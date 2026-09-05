-- ─────────────────────────────────────────────────────────────────────────────
-- Проверки синхронизации: выгрузка изменений и приём очереди с устройства.
-- ─────────────────────────────────────────────────────────────────────────────

\set QUIET on
\pset pager off

create or replace function pg_temp.expect(p_actual text, p_expected text, p_what text)
returns void language plpgsql as $$
begin
  if p_actual is distinct from p_expected then
    raise exception 'ПРОВАЛ: % — ожидалось %, получено %', p_what, p_expected, p_actual;
  end if;
  raise notice '  ok  %', p_what;
end;
$$;

create or replace function pg_temp.expect_denied(p_sql text, p_what text)
returns void language plpgsql as $$
begin
  begin
    execute p_sql;
  exception when others then
    raise notice '  ok  % (отказ: %)', p_what, left(sqlerrm, 55);
    return;
  end;
  raise exception 'ПРОВАЛ: % — операция прошла, хотя должна была быть отклонена', p_what;
end;
$$;

create or replace function pg_temp.login(p_user uuid)
returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', p_user::text, false);
end;
$$;

-- ── Сцена ────────────────────────────────────────────────────────────────────
insert into auth.users (id, email) values
  ('44444444-4444-4444-4444-444444444444', 'owner-sync-a@test.local'),
  ('55555555-5555-5555-5555-555555555555', 'staff-sync-a@test.local'),
  ('66666666-6666-6666-6666-666666666666', 'owner-sync-b@test.local');

insert into public.organizations (id, name) values
  ('cccccccc-0000-0000-0000-000000000001', 'Организация С'),
  ('dddddddd-0000-0000-0000-000000000001', 'Организация Д');

insert into public.establishments (id, org_id, name) values
  ('cccccccc-0000-0000-0000-0000000000e1', 'cccccccc-0000-0000-0000-000000000001', 'Кофейня С'),
  ('dddddddd-0000-0000-0000-0000000000e1', 'dddddddd-0000-0000-0000-000000000001', 'Ресторан Д');

insert into public.memberships (user_id, org_id, establishment_id, role) values
  ('44444444-4444-4444-4444-444444444444', 'cccccccc-0000-0000-0000-000000000001', null, 'owner'),
  ('55555555-5555-5555-5555-555555555555', 'cccccccc-0000-0000-0000-000000000001',
   'cccccccc-0000-0000-0000-0000000000e1', 'staff'),
  ('66666666-6666-6666-6666-666666666666', 'dddddddd-0000-0000-0000-000000000001', null, 'owner');

do $prf$ begin raise notice ''; raise notice '1. Выгрузка изменений'; end $prf$;

set role authenticated;
do $prf$ begin perform pg_temp.login('44444444-4444-4444-4444-444444444444'); end $prf$;

do $prf$ begin
  perform pg_temp.expect(
    jsonb_array_length(app.pull_changes('cccccccc-0000-0000-0000-0000000000e1') -> 'products')::text,
    '0', 'на пустом заведении товаров нет');
end $prf$;

do $prf$ begin
  perform pg_temp.expect(
    (app.pull_changes('cccccccc-0000-0000-0000-0000000000e1') ? 'server_time')::text,
    'true', 'ответ содержит курсор server_time');
end $prf$;

do $prf$ begin
  perform pg_temp.expect_denied(
    $q$ select app.pull_changes('dddddddd-0000-0000-0000-0000000000e1') $q$,
    'выгрузка из чужого заведения отклоняется');
end $prf$;

do $prf$ begin raise notice ''; raise notice '2. Приём справочника'; end $prf$;

do $prf$
declare v jsonb;
begin
  v := app.push_changes('cccccccc-0000-0000-0000-0000000000e1', jsonb_build_array(
    jsonb_build_object('table', 'products', 'row', jsonb_build_object(
      'id', 'cccccccc-0000-0000-0000-0000000000c1',
      'name', 'Кофе зерновой', 'unit', 'кг', 'inventory_unit', 'кг', 'min_stock', 2.5))));
  perform pg_temp.expect((v ->> 'applied'), '1', 'товар принят');
end $prf$;

do $prf$ begin
  perform pg_temp.expect(
    (select name from public.products where id = 'cccccccc-0000-0000-0000-0000000000c1'),
    'Кофе зерновой', 'товар лежит в базе');
end $prf$;

do $prf$ begin
  perform pg_temp.expect(
    jsonb_array_length(app.pull_changes('cccccccc-0000-0000-0000-0000000000e1') -> 'products')::text,
    '1', 'выгрузка отдаёт принятый товар');
end $prf$;

do $prf$ begin raise notice ''; raise notice '3. Курсор'; end $prf$;

-- Курсор хранится в таблице, а не в переменной: внутри одного DO-блока
-- транзакция одна, now() не меняется, и проверка ничего не доказала бы.
create temp table sync_cursor (label text primary key, value timestamptz);

insert into sync_cursor
select 'exact', (app.pull_changes('cccccccc-0000-0000-0000-0000000000e1') ->> 'server_time')::timestamptz;

do $prf$ begin
  perform pg_temp.expect(
    jsonb_array_length(app.pull_changes('cccccccc-0000-0000-0000-0000000000e1',
      (select value from sync_cursor where label = 'exact')) -> 'products')::text,
    '0', 'по точному времени сервера уже полученное не приходит повторно');
end $prf$;

do $prf$ begin
  perform pg_temp.expect(
    jsonb_array_length(app.pull_changes('cccccccc-0000-0000-0000-0000000000e1',
      (select (app.pull_changes('cccccccc-0000-0000-0000-0000000000e1') ->> 'next_cursor')::timestamptz))
      -> 'products')::text,
    '1', 'next_cursor отводится назад и подстраховывает повторной выдачей');
end $prf$;

do $prf$ begin raise notice ''; raise notice '4. Мягкое удаление доезжает'; end $prf$;

insert into sync_cursor
select 'before_delete', (app.pull_changes('cccccccc-0000-0000-0000-0000000000e1') ->> 'server_time')::timestamptz;

do $prf$ begin perform pg_sleep(0.05); end $prf$;

do $prf$ begin
  perform app.push_changes('cccccccc-0000-0000-0000-0000000000e1', jsonb_build_array(
    jsonb_build_object('table', 'products', 'row', jsonb_build_object(
      'id', 'cccccccc-0000-0000-0000-0000000000c1',
      'name', 'Кофе зерновой', 'deleted_at', now()))));
end $prf$;

do $prf$
declare v jsonb;
begin
  v := app.pull_changes('cccccccc-0000-0000-0000-0000000000e1',
         (select value from sync_cursor where label = 'before_delete'));
  perform pg_temp.expect(jsonb_array_length(v -> 'products')::text, '1',
    'удалённая строка приходит в выгрузке');
  perform pg_temp.expect(((v -> 'products' -> 0 ->> 'deleted_at') is not null)::text,
    'true', 'у неё проставлен признак удаления');
end $prf$;

do $prf$ begin raise notice ''; raise notice '5. Смена принимается один раз'; end $prf$;

do $prf$
declare v jsonb;
begin
  v := app.push_changes('cccccccc-0000-0000-0000-0000000000e1', jsonb_build_array(
    jsonb_build_object(
      'table', 'shifts',
      'row', jsonb_build_object(
        'id', 'cccccccc-0000-0000-0000-0000000000f1',
        'closed_at', now(),
        'revenue_minor', 12345650,
        'cash_minor', 12345650,
        'staff_names', jsonb_build_array('Бариста 1', 'Бариста 2')),
      'children', jsonb_build_array(
        jsonb_build_object('id', 'cccccccc-0000-0000-0000-0000000000f2',
                           'product_name', 'Молоко', 'quantity', 2.5, 'unit', 'л')))));
  perform pg_temp.expect((v ->> 'applied'), '1', 'смена принята');
end $prf$;

do $prf$
declare v jsonb;
begin
  -- Повторная отправка той же смены из очереди синхронизации.
  v := app.push_changes('cccccccc-0000-0000-0000-0000000000e1', jsonb_build_array(
    jsonb_build_object('table', 'shifts', 'row', jsonb_build_object(
      'id', 'cccccccc-0000-0000-0000-0000000000f1',
      'closed_at', now(), 'revenue_minor', 99999999))));
  perform pg_temp.expect((v ->> 'skipped'), '1', 'повтор отмечен как пропущенный');
end $prf$;

do $prf$ begin
  perform pg_temp.expect((select count(*)::text from public.shifts), '1',
    'дубля смены не появилось');
  perform pg_temp.expect(
    (select revenue_minor::text from public.shifts where id = 'cccccccc-0000-0000-0000-0000000000f1'),
    '12345650', 'повтор не перезаписал выручку');
  perform pg_temp.expect((select count(*)::text from public.shift_writeoffs), '1',
    'списание записано один раз');
end $prf$;

do $prf$ begin
  perform pg_temp.expect(
    jsonb_array_length(
      (app.pull_changes('cccccccc-0000-0000-0000-0000000000e1') -> 'shifts' -> 0 -> 'writeoffs'))::text,
    '1', 'смена выгружается вместе со списаниями');
end $prf$;

do $prf$ begin raise notice ''; raise notice '6. Остатки: побеждает позднее измерение'; end $prf$;

do $prf$
declare v jsonb;
begin
  perform app.push_changes('cccccccc-0000-0000-0000-0000000000e1', jsonb_build_array(
    jsonb_build_object('table', 'stock_levels', 'row', jsonb_build_object(
      'product_id', 'cccccccc-0000-0000-0000-0000000000c1',
      'remaining', 10, 'measured_at', now()))));

  -- Устройство, которое было оффлайн, присылает более раннее измерение.
  v := app.push_changes('cccccccc-0000-0000-0000-0000000000e1', jsonb_build_array(
    jsonb_build_object('table', 'stock_levels', 'row', jsonb_build_object(
      'product_id', 'cccccccc-0000-0000-0000-0000000000c1',
      'remaining', 999, 'measured_at', now() - interval '1 hour'))));

  perform pg_temp.expect((v ->> 'skipped'), '1', 'устаревшее измерение отклонено');
  perform pg_temp.expect(
    (select remaining::text from public.stock_levels
     where product_id = 'cccccccc-0000-0000-0000-0000000000c1'),
    '10.000', 'остаток не перезаписан устаревшим значением');
end $prf$;

do $prf$ begin raise notice ''; raise notice '7. Изоляция при приёме'; end $prf$;

do $prf$ begin
  perform pg_temp.expect_denied(
    $q$ select app.push_changes('dddddddd-0000-0000-0000-0000000000e1', jsonb_build_array(
          jsonb_build_object('table', 'products', 'row', jsonb_build_object(
            'id', gen_random_uuid(), 'name', 'Чужой товар')))) $q$,
    'запись в чужое заведение отклоняется');
end $prf$;

do $prf$
declare v jsonb;
begin
  -- Клиент пытается подсунуть чужое заведение прямо в данных строки.
  v := app.push_changes('cccccccc-0000-0000-0000-0000000000e1', jsonb_build_array(
    jsonb_build_object('table', 'products', 'row', jsonb_build_object(
      'id', 'cccccccc-0000-0000-0000-0000000000c9',
      'establishment_id', 'dddddddd-0000-0000-0000-0000000000e1',
      'name', 'Подмена'))));
  perform pg_temp.expect(
    (select establishment_id::text from public.products
     where id = 'cccccccc-0000-0000-0000-0000000000c9'),
    'cccccccc-0000-0000-0000-0000000000e1',
    'establishment_id из данных клиента игнорируется');
end $prf$;

do $prf$ begin raise notice ''; raise notice '8. Роли и некорректный ввод'; end $prf$;

do $prf$ begin
  perform pg_temp.login('55555555-5555-5555-5555-555555555555');
  perform pg_temp.expect_denied(
    $q$ select app.push_changes('cccccccc-0000-0000-0000-0000000000e1', jsonb_build_array(
          jsonb_build_object('table', 'products', 'row', jsonb_build_object(
            'id', gen_random_uuid(), 'name', 'Товар от сотрудника')))) $q$,
    'сотрудник не может менять справочник через синхронизацию');
end $prf$;

do $prf$
declare v jsonb;
begin
  -- А смену закрыть обязан уметь.
  v := app.push_changes('cccccccc-0000-0000-0000-0000000000e1', jsonb_build_array(
    jsonb_build_object('table', 'shifts', 'row', jsonb_build_object(
      'id', 'cccccccc-0000-0000-0000-0000000000fa',
      'closed_at', now(), 'revenue_minor', 5000))));
  perform pg_temp.expect((v ->> 'applied'), '1', 'сотрудник закрывает смену через синхронизацию');
end $prf$;

do $prf$ begin
  perform pg_temp.login('44444444-4444-4444-4444-444444444444');
  perform pg_temp.expect_denied(
    $q$ select app.push_changes('cccccccc-0000-0000-0000-0000000000e1', jsonb_build_array(
          jsonb_build_object('table', 'auth_users', 'row', jsonb_build_object('id', gen_random_uuid())))) $q$,
    'неизвестная таблица отклоняется');
  perform pg_temp.expect_denied(
    $q$ select app.push_changes('cccccccc-0000-0000-0000-0000000000e1', '{"не":"массив"}'::jsonb) $q$,
    'не массив операций отклоняется');
  perform pg_temp.expect_denied(
    $q$ select app.push_changes('cccccccc-0000-0000-0000-0000000000e1', jsonb_build_array(
          jsonb_build_object('table', 'products'))) $q$,
    'операция без данных строки отклоняется');
end $prf$;

do $prf$ begin raise notice ''; raise notice 'Проверки синхронизации пройдены.'; raise notice ''; end $prf$;
