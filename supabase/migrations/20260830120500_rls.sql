-- ─────────────────────────────────────────────────────────────────────────────
-- Разграничение доступа средствами PostgreSQL.
--
-- Изоляция арендаторов держится на RLS, а не на проверках в коде приложения:
-- даже запрос без фильтра вернёт только строки своих заведений.
--
-- Разделение ролей: сотрудник смены (staff) заводит операции, но не может
-- менять справочники. Владелец и управляющий могут всё в своих точках.
-- ─────────────────────────────────────────────────────────────────────────────

grant usage on schema app to authenticated;
grant execute on function app.member_establishments()  to authenticated;
grant execute on function app.can_read(uuid)           to authenticated;
grant execute on function app.can_manage(uuid)         to authenticated;
grant execute on function app.is_org_owner(uuid)       to authenticated;

-- ── Организации ──────────────────────────────────────────────────────────────
alter table public.organizations enable row level security;
grant select, insert, update on public.organizations to authenticated;

create policy organizations_read on public.organizations
  for select to authenticated
  using (exists (
    select 1 from public.memberships m
    where m.org_id = organizations.id
      and m.user_id = auth.uid()
      and m.deleted_at is null
  ));

create policy organizations_update on public.organizations
  for update to authenticated
  using (exists (
    select 1 from public.memberships m
    where m.org_id = organizations.id
      and m.user_id = auth.uid()
      and m.role = 'owner'
      and m.deleted_at is null
  ));

-- Создать организацию может любой авторизованный: это регистрация нового
-- клиента. Членство владельца заводится следом, в одной транзакции.
create policy organizations_insert on public.organizations
  for insert to authenticated
  with check (true);

-- ── Заведения ────────────────────────────────────────────────────────────────
alter table public.establishments enable row level security;
grant select, insert, update on public.establishments to authenticated;

create policy establishments_read on public.establishments
  for select to authenticated
  using (app.can_read(id));

create policy establishments_update on public.establishments
  for update to authenticated
  using (app.can_manage(id))
  with check (app.can_manage(id));

create policy establishments_insert on public.establishments
  for insert to authenticated
  with check (exists (
    select 1 from public.memberships m
    where m.org_id = establishments.org_id
      and m.user_id = auth.uid()
      and m.role = 'owner'
      and m.deleted_at is null
  ));

-- ── Участники ────────────────────────────────────────────────────────────────
alter table public.memberships enable row level security;
grant select, insert, update on public.memberships to authenticated;

-- Своё членство видно всегда — иначе новый пользователь не смог бы
-- узнать, куда у него есть доступ.
create policy memberships_read_own on public.memberships
  for select to authenticated
  using (user_id = auth.uid());

-- Владелец видит и заводит участников своей организации. Подзапрос обращается
-- к той же таблице, поэтому идёт через security definer — иначе рекурсия.
create policy memberships_manage_by_owner on public.memberships
  for all to authenticated
  using (app.is_org_owner(org_id))
  with check (app.is_org_owner(org_id));

-- ── Справочники: читают все участники, правят управляющие ────────────────────
do $$
declare
  t text;
begin
  foreach t in array array['departments', 'categories', 'products', 'staff_members',
                           'reminders', 'export_templates']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);

    execute format($f$
      create policy %I on public.%I
        for select to authenticated
        using (app.can_read(establishment_id))
    $f$, t || '_read', t);

    execute format($f$
      create policy %I on public.%I
        for all to authenticated
        using (app.can_manage(establishment_id))
        with check (app.can_manage(establishment_id))
    $f$, t || '_manage', t);
  end loop;
end
$$;

-- ── Операции: заводит любой участник, правит только управляющий ──────────────
do $$
declare
  t text;
begin
  foreach t in array array['shifts', 'requests', 'inventories']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('grant select, insert, update on public.%I to authenticated', t);

    execute format($f$
      create policy %I on public.%I
        for select to authenticated
        using (app.can_read(establishment_id))
    $f$, t || '_read', t);

    -- Сотрудник смены обязан иметь право вставки: он закрывает смены
    -- и оформляет заявки. Это и есть его работа.
    execute format($f$
      create policy %I on public.%I
        for insert to authenticated
        with check (app.can_read(establishment_id))
    $f$, t || '_insert', t);

    -- Правка задним числом — только для управляющего.
    execute format($f$
      create policy %I on public.%I
        for update to authenticated
        using (app.can_manage(establishment_id))
        with check (app.can_manage(establishment_id))
    $f$, t || '_update', t);
  end loop;
end
$$;

-- ── Дочерние строки наследуют доступ от родителя ──────────────────────────────
alter table public.shift_writeoffs enable row level security;
grant select, insert on public.shift_writeoffs to authenticated;

create policy shift_writeoffs_read on public.shift_writeoffs
  for select to authenticated
  using (exists (
    select 1 from public.shifts s
    where s.id = shift_writeoffs.shift_id and app.can_read(s.establishment_id)
  ));

create policy shift_writeoffs_insert on public.shift_writeoffs
  for insert to authenticated
  with check (exists (
    select 1 from public.shifts s
    where s.id = shift_writeoffs.shift_id and app.can_read(s.establishment_id)
  ));

alter table public.request_items enable row level security;
grant select, insert on public.request_items to authenticated;

create policy request_items_read on public.request_items
  for select to authenticated
  using (exists (
    select 1 from public.requests r
    where r.id = request_items.request_id and app.can_read(r.establishment_id)
  ));

create policy request_items_insert on public.request_items
  for insert to authenticated
  with check (exists (
    select 1 from public.requests r
    where r.id = request_items.request_id and app.can_read(r.establishment_id)
  ));

alter table public.inventory_items enable row level security;
grant select, insert on public.inventory_items to authenticated;

create policy inventory_items_read on public.inventory_items
  for select to authenticated
  using (exists (
    select 1 from public.inventories i
    where i.id = inventory_items.inventory_id and app.can_read(i.establishment_id)
  ));

create policy inventory_items_insert on public.inventory_items
  for insert to authenticated
  with check (exists (
    select 1 from public.inventories i
    where i.id = inventory_items.inventory_id and app.can_read(i.establishment_id)
  ));

-- ── Остатки ──────────────────────────────────────────────────────────────────
alter table public.stock_levels enable row level security;
grant select, insert, update on public.stock_levels to authenticated;

create policy stock_levels_read on public.stock_levels
  for select to authenticated
  using (app.can_read(establishment_id));

create policy stock_levels_write on public.stock_levels
  for all to authenticated
  using (app.can_read(establishment_id))
  with check (app.can_read(establishment_id));

-- ── Интеграция iiko ──────────────────────────────────────────────────────────
-- Клиенту не выдаётся право select вообще: ключ не должен покидать сервер
-- даже в зашифрованном виде. Приложение узнаёт о состоянии интеграции
-- через отдельное представление без ключа.
alter table public.iiko_integrations enable row level security;
revoke all on public.iiko_integrations from authenticated, anon;

-- Права выдаются поколоночно: api_login_enc в список не входит, поэтому
-- даже select * по таблице завершится отказом. Ключ физически недоступен клиенту.
grant select (establishment_id, organization_id, organization_name, store_ids, last_sync_at)
  on public.iiko_integrations to authenticated;

create policy iiko_read on public.iiko_integrations
  for select to authenticated
  using (app.can_manage(establishment_id));

create view public.iiko_status
with (security_invoker = true) as
  select establishment_id,
         organization_id,
         organization_name,
         store_ids,
         last_sync_at,
         true as is_connected
  from public.iiko_integrations;

comment on view public.iiko_status is
  'Состояние интеграции без ключа доступа. Сам ключ доступен только серверным функциям.';

grant select on public.iiko_status to authenticated;

-- Запись ключа идёт только через серверную функцию: она шифрует значение
-- и никогда не возвращает его обратно.
create or replace function public.connect_iiko(
  p_establishment uuid,
  p_api_login     text,
  p_secret        text
)
returns void
language plpgsql
security definer
set search_path = public, app, auth, extensions, pg_temp
as $$
begin
  if not app.can_manage(p_establishment) then
    raise exception 'Недостаточно прав для настройки интеграции'
      using errcode = '42501';
  end if;

  insert into public.iiko_integrations (establishment_id, api_login_enc)
  values (p_establishment, pgp_sym_encrypt(p_api_login, p_secret))
  on conflict (establishment_id) do update
    set api_login_enc = excluded.api_login_enc,
        updated_at    = now();
end;
$$;

comment on function public.connect_iiko(uuid, text, text) is
  'Сохраняет ключ iiko в зашифрованном виде. Обратно ключ не отдаётся никогда.';

revoke all on function public.connect_iiko(uuid, text, text) from public, anon;
grant execute on function public.connect_iiko(uuid, text, text) to authenticated;
