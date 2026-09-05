-- ─────────────────────────────────────────────────────────────────────────────
-- Синхронизация: выгрузка изменений и приём изменений с устройства.
--
-- Две функции образуют весь протокол обмена. Устройство спрашивает
-- «что изменилось после этой метки» и отправляет накопленную очередь.
--
-- Правила разрешения конфликтов различаются по типу данных:
--
--  * Справочники (отделы, категории, товары, сотрудники, напоминания,
--    шаблоны) — побеждает последняя дошедшая запись. Их правит только
--    администратор, конфликты редки и безобидны.
--
--  * Операции (смены, заявки, инвентаризации) — только добавление.
--    Повтор гасится по первичному ключу: закрытая смена это факт,
--    а не изменяемая строка, и версии с двух устройств не сливаются.
--
--  * Остатки — побеждает более позднее измерение по measured_at,
--    а не по времени прихода: устройство могло отправить старое
--    измерение позже нового.
-- ─────────────────────────────────────────────────────────────────────────────

-- Насколько курсор отводится назад от времени сервера.
-- Должен превышать длительность самой долгой пишущей транзакции.
create or replace function app.sync_cursor_lag()
returns interval
language sql
immutable
as $$ select interval '5 seconds' $$;

comment on function app.sync_cursor_lag() is
  'Отступ курсора назад. Закрывает окно, в котором транзакция, начавшаяся до выборки и завершившаяся после неё, была бы потеряна.';

-- ── Выгрузка изменений ───────────────────────────────────────────────────────
create or replace function app.pull_changes(
  p_establishment uuid,
  p_since         timestamptz default '-infinity'::timestamptz
)
returns jsonb
language plpgsql
stable
security invoker
as $$
declare
  v_now timestamptz := now();
begin
  if not app.can_read(p_establishment) then
    raise exception 'Нет доступа к заведению %', p_establishment
      using errcode = '42501';
  end if;

  return jsonb_build_object(
    -- Время сервера на момент выборки. Курсор берётся отсюда, а не
    -- с устройства: часы на телефонах врут, и выборка по клиентскому
    -- времени тихо теряет записи.
    'server_time', v_now,

    -- А хранить устройство должно именно next_cursor, а не server_time.
    --
    -- updated_at проставляется как now(), то есть временем НАЧАЛА
    -- транзакции. Транзакция, начавшаяся до нашей выборки и завершившаяся
    -- после неё, получит метку меньше server_time — и при следующем
    -- запросе «что изменилось после server_time» не попадёт в выборку
    -- никогда. Запись потеряется молча.
    --
    -- Отступ назад закрывает это окно. Часть строк приедет повторно,
    -- но это безвредно: приём идемпотентен — справочники перезаписываются
    -- тем же значением, операции гасятся по первичному ключу.
    'next_cursor', v_now - app.sync_cursor_lag(),

    'departments', coalesce((
      select jsonb_agg(to_jsonb(t) order by t.updated_at)
      from public.departments t
      where t.establishment_id = p_establishment and t.updated_at > p_since
    ), '[]'::jsonb),

    'categories', coalesce((
      select jsonb_agg(to_jsonb(t) order by t.updated_at)
      from public.categories t
      where t.establishment_id = p_establishment and t.updated_at > p_since
    ), '[]'::jsonb),

    'products', coalesce((
      select jsonb_agg(to_jsonb(t) order by t.updated_at)
      from public.products t
      where t.establishment_id = p_establishment and t.updated_at > p_since
    ), '[]'::jsonb),

    'staff_members', coalesce((
      select jsonb_agg(to_jsonb(t) order by t.updated_at)
      from public.staff_members t
      where t.establishment_id = p_establishment and t.updated_at > p_since
    ), '[]'::jsonb),

    'reminders', coalesce((
      select jsonb_agg(to_jsonb(t) order by t.updated_at)
      from public.reminders t
      where t.establishment_id = p_establishment and t.updated_at > p_since
    ), '[]'::jsonb),

    'export_templates', coalesce((
      select jsonb_agg(to_jsonb(t) order by t.updated_at)
      from public.export_templates t
      where t.establishment_id = p_establishment and t.updated_at > p_since
    ), '[]'::jsonb),

    -- Смены отдаются вместе со списаниями: у дочерней таблицы нет своей
    -- метки времени, и разделять их незачем — смена неизменяема.
    'shifts', coalesce((
      select jsonb_agg(
               to_jsonb(t) || jsonb_build_object('writeoffs', coalesce((
                 select jsonb_agg(to_jsonb(w))
                 from public.shift_writeoffs w
                 where w.shift_id = t.id
               ), '[]'::jsonb))
               order by t.updated_at)
      from public.shifts t
      where t.establishment_id = p_establishment and t.updated_at > p_since
    ), '[]'::jsonb),

    'stock_levels', coalesce((
      select jsonb_agg(to_jsonb(t) order by t.updated_at)
      from public.stock_levels t
      where t.establishment_id = p_establishment and t.updated_at > p_since
    ), '[]'::jsonb)
  );
end;
$$;

comment on function app.pull_changes(uuid, timestamptz) is
  'Всё изменённое в заведении после метки, включая мягко удалённое. Устройство сохраняет next_cursor из ответа и передаёт его в следующий вызов.';

-- ── Приём изменений ──────────────────────────────────────────────────────────
create or replace function app.push_changes(
  p_establishment uuid,
  p_ops           jsonb
)
returns jsonb
language plpgsql
security invoker
as $$
declare
  v_op      jsonb;
  v_table   text;
  v_row     jsonb;
  v_applied integer := 0;
  v_skipped integer := 0;
  v_child   jsonb;
begin
  if not app.can_read(p_establishment) then
    raise exception 'Нет доступа к заведению %', p_establishment
      using errcode = '42501';
  end if;

  if jsonb_typeof(p_ops) <> 'array' then
    raise exception 'Ожидался массив операций, получено %', jsonb_typeof(p_ops)
      using errcode = '22023';
  end if;

  for v_op in select value from jsonb_array_elements(p_ops)
  loop
    v_table := v_op ->> 'table';
    v_row   := v_op -> 'row';

    if v_row is null or jsonb_typeof(v_row) <> 'object' then
      raise exception 'Операция без данных строки: %', v_op
        using errcode = '22023';
    end if;

    -- establishment_id берётся из аргумента, а не из присланных данных:
    -- клиент не должен иметь возможности записать что-то в чужое заведение.
    case v_table

      when 'departments' then
        insert into public.departments
          (id, establishment_id, name, icon_key, sort_order, created_at, deleted_at)
        values (
          (v_row ->> 'id')::uuid, p_establishment,
          v_row ->> 'name',
          coalesce(v_row ->> 'icon_key', 'category'),
          coalesce((v_row ->> 'sort_order')::integer, 0),
          coalesce((v_row ->> 'created_at')::timestamptz, now()),
          (v_row ->> 'deleted_at')::timestamptz
        )
        on conflict (id) do update set
          name       = excluded.name,
          icon_key   = excluded.icon_key,
          sort_order = excluded.sort_order,
          deleted_at = excluded.deleted_at;
        v_applied := v_applied + 1;

      when 'categories' then
        insert into public.categories
          (id, establishment_id, department_id, name, sort_order, created_at, deleted_at)
        values (
          (v_row ->> 'id')::uuid, p_establishment,
          (v_row ->> 'department_id')::uuid,
          v_row ->> 'name',
          coalesce((v_row ->> 'sort_order')::integer, 0),
          coalesce((v_row ->> 'created_at')::timestamptz, now()),
          (v_row ->> 'deleted_at')::timestamptz
        )
        on conflict (id) do update set
          department_id = excluded.department_id,
          name          = excluded.name,
          sort_order    = excluded.sort_order,
          deleted_at    = excluded.deleted_at;
        v_applied := v_applied + 1;

      when 'products' then
        insert into public.products
          (id, establishment_id, category_id, name, unit, inventory_unit,
           min_stock, sort_order, created_at, deleted_at)
        values (
          (v_row ->> 'id')::uuid, p_establishment,
          (v_row ->> 'category_id')::uuid,
          v_row ->> 'name',
          coalesce(v_row ->> 'unit', 'шт'),
          coalesce(v_row ->> 'inventory_unit', 'шт'),
          (v_row ->> 'min_stock')::numeric,
          coalesce((v_row ->> 'sort_order')::integer, 0),
          coalesce((v_row ->> 'created_at')::timestamptz, now()),
          (v_row ->> 'deleted_at')::timestamptz
        )
        on conflict (id) do update set
          category_id    = excluded.category_id,
          name           = excluded.name,
          unit           = excluded.unit,
          inventory_unit = excluded.inventory_unit,
          min_stock      = excluded.min_stock,
          sort_order     = excluded.sort_order,
          deleted_at     = excluded.deleted_at;
        v_applied := v_applied + 1;

      when 'staff_members' then
        insert into public.staff_members
          (id, establishment_id, full_name, is_active, created_at, deleted_at)
        values (
          (v_row ->> 'id')::uuid, p_establishment,
          v_row ->> 'full_name',
          coalesce((v_row ->> 'is_active')::boolean, true),
          coalesce((v_row ->> 'created_at')::timestamptz, now()),
          (v_row ->> 'deleted_at')::timestamptz
        )
        on conflict (id) do update set
          full_name  = excluded.full_name,
          is_active  = excluded.is_active,
          deleted_at = excluded.deleted_at;
        v_applied := v_applied + 1;

      -- Смена приходит вместе со списаниями и записывается только один раз.
      when 'shifts' then
        insert into public.shifts
          (id, establishment_id, closed_at, closed_by, staff_names,
           revenue_minor, qr_minor, card_minor, cash_minor,
           morning_cash_minor, evening_cash_minor, inkass_minor, created_at)
        values (
          (v_row ->> 'id')::uuid, p_establishment,
          (v_row ->> 'closed_at')::timestamptz,
          auth.uid(),
          coalesce(
            (select array_agg(value::text)
             from jsonb_array_elements_text(coalesce(v_row -> 'staff_names', '[]'::jsonb))),
            '{}'::text[]),
          coalesce((v_row ->> 'revenue_minor')::bigint, 0),
          coalesce((v_row ->> 'qr_minor')::bigint, 0),
          coalesce((v_row ->> 'card_minor')::bigint, 0),
          coalesce((v_row ->> 'cash_minor')::bigint, 0),
          coalesce((v_row ->> 'morning_cash_minor')::bigint, 0),
          coalesce((v_row ->> 'evening_cash_minor')::bigint, 0),
          coalesce((v_row ->> 'inkass_minor')::bigint, 0),
          coalesce((v_row ->> 'created_at')::timestamptz, now())
        )
        on conflict (id) do nothing;

        if found then
          v_applied := v_applied + 1;
          for v_child in
            select value from jsonb_array_elements(coalesce(v_op -> 'children', '[]'::jsonb))
          loop
            insert into public.shift_writeoffs
              (id, shift_id, product_name, quantity, unit, created_at)
            values (
              (v_child ->> 'id')::uuid,
              (v_row ->> 'id')::uuid,
              v_child ->> 'product_name',
              (v_child ->> 'quantity')::numeric,
              coalesce(v_child ->> 'unit', 'шт'),
              coalesce((v_child ->> 'created_at')::timestamptz, now())
            )
            on conflict (id) do nothing;
          end loop;
        else
          -- Смена уже была принята: повторная отправка из очереди
          -- не должна удваивать выручку.
          v_skipped := v_skipped + 1;
        end if;

      -- Побеждает более позднее измерение, а не более поздняя отправка.
      when 'stock_levels' then
        insert into public.stock_levels
          (establishment_id, product_id, remaining, measured_at)
        values (
          p_establishment,
          (v_row ->> 'product_id')::uuid,
          (v_row ->> 'remaining')::numeric,
          (v_row ->> 'measured_at')::timestamptz
        )
        on conflict (establishment_id, product_id) do update set
          remaining   = excluded.remaining,
          measured_at = excluded.measured_at,
          updated_at  = now()
        where public.stock_levels.measured_at < excluded.measured_at;

        if found then
          v_applied := v_applied + 1;
        else
          v_skipped := v_skipped + 1;
        end if;

      else
        raise exception 'Синхронизация таблицы "%" не поддерживается', v_table
          using errcode = '22023';
    end case;
  end loop;

  return jsonb_build_object(
    'applied',     v_applied,
    'skipped',     v_skipped,
    'server_time', now()
  );
end;
$$;

comment on function app.push_changes(uuid, jsonb) is
  'Принимает очередь изменений с устройства. Справочники обновляются, операции только добавляются, остатки — по времени измерения.';

grant execute on function app.sync_cursor_lag()                 to authenticated;
grant execute on function app.pull_changes(uuid, timestamptz)   to authenticated;
grant execute on function app.push_changes(uuid, jsonb)        to authenticated;
