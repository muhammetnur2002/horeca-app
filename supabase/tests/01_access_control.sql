-- ─────────────────────────────────────────────────────────────────────────────
-- Проверки разграничения доступа.
--
-- Запускать на чистой базе с применёнными миграциями:
--   psql -d akyl -v ON_ERROR_STOP=1 -f tests/01_access_control.sql
--
-- Любая неудавшаяся проверка прерывает выполнение с понятным сообщением.
-- ─────────────────────────────────────────────────────────────────────────────

\set QUIET on
\pset pager off

-- ── Вспомогательные ──────────────────────────────────────────────────────────
create or replace function pg_temp.expect(p_actual bigint, p_expected bigint, p_what text)
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
    raise notice '  ok  % (отказ: %)', p_what, left(sqlerrm, 60);
    return;
  end;
  raise exception 'ПРОВАЛ: % — операция прошла, хотя должна была быть отклонена', p_what;
end;
$$;

-- Для UPDATE и DELETE политика RLS не выбрасывает ошибку: она просто
-- отфильтровывает недоступные строки, и запрос завершается успехом
-- с нулём изменений. Поэтому «отказано» — это либо исключение,
-- либо ноль затронутых строк.
create or replace function pg_temp.expect_no_effect(p_sql text, p_what text)
returns void language plpgsql as $$
declare
  v_rows bigint;
begin
  begin
    execute p_sql;
    get diagnostics v_rows = row_count;
  exception when others then
    raise notice '  ok  % (отказ: %)', p_what, left(sqlerrm, 60);
    return;
  end;
  if v_rows > 0 then
    raise exception 'ПРОВАЛ: % — изменено строк: %', p_what, v_rows;
  end if;
  raise notice '  ok  % (изменено строк: 0)', p_what;
end;
$$;

create or replace function pg_temp.login(p_user uuid)
returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', p_user::text, false);
end;
$$;

-- ── Данные для проверок ──────────────────────────────────────────────────────
-- Готовим от суперпользователя, чтобы RLS не мешала расстановке сцены.
\echo ''
\echo 'Подготовка: две независимые организации'

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'owner-a@test.local'),
  ('22222222-2222-2222-2222-222222222222', 'staff-a@test.local'),
  ('33333333-3333-3333-3333-333333333333', 'owner-b@test.local');

insert into public.organizations (id, name) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Организация А'),
  ('bbbbbbbb-0000-0000-0000-000000000001', 'Организация Б');

insert into public.establishments (id, org_id, name) values
  ('aaaaaaaa-0000-0000-0000-0000000000e1', 'aaaaaaaa-0000-0000-0000-000000000001', 'Кофейня А'),
  ('bbbbbbbb-0000-0000-0000-0000000000e1', 'bbbbbbbb-0000-0000-0000-000000000001', 'Ресторан Б');

insert into public.memberships (user_id, org_id, establishment_id, role) values
  ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-0000-0000-000000000001', null, 'owner'),
  ('22222222-2222-2222-2222-222222222222', 'aaaaaaaa-0000-0000-0000-000000000001',
   'aaaaaaaa-0000-0000-0000-0000000000e1', 'staff'),
  ('33333333-3333-3333-3333-333333333333', 'bbbbbbbb-0000-0000-0000-000000000001', null, 'owner');

insert into public.departments (id, establishment_id, name, icon_key) values
  ('aaaaaaaa-0000-0000-0000-0000000000d1', 'aaaaaaaa-0000-0000-0000-0000000000e1', 'Бар', 'local_bar'),
  ('bbbbbbbb-0000-0000-0000-0000000000d1', 'bbbbbbbb-0000-0000-0000-0000000000e1', 'Кухня', 'kitchen');

insert into public.products (id, establishment_id, name, unit) values
  ('aaaaaaaa-0000-0000-0000-0000000000c1', 'aaaaaaaa-0000-0000-0000-0000000000e1', 'Кофе зерновой', 'кг'),
  ('bbbbbbbb-0000-0000-0000-0000000000c1', 'bbbbbbbb-0000-0000-0000-0000000000e1', 'Томаты', 'кг');

\echo ''
\echo '1. Изоляция арендаторов'

set role authenticated;
do $prf$ begin
  perform pg_temp.login('11111111-1111-1111-1111-111111111111');
end $prf$;

do $prf$ begin
  perform pg_temp.expect((select count(*) from public.products),
                      1, 'владелец А видит только свой товар');
end $prf$;
do $prf$ begin
  perform pg_temp.expect((select count(*) from public.establishments),
                      1, 'владелец А видит только своё заведение');
end $prf$;
do $prf$ begin
  perform pg_temp.expect((select count(*) from public.departments),
                      1, 'владелец А видит только свои отделы');
end $prf$;

do $prf$ begin
  perform pg_temp.login('33333333-3333-3333-3333-333333333333');
end $prf$;
do $prf$ begin
  perform pg_temp.expect((select count(*) from public.products),
                      1, 'владелец Б видит только свой товар');
end $prf$;
do $prf$ begin
  perform pg_temp.expect((select count(*) from public.products
                       where name = 'Кофе зерновой'),
                      0, 'товар организации А невидим для Б');
end $prf$;

\echo ''
\echo '2. Запрос без фильтра не обходит изоляцию'

do $prf$ begin
  perform pg_temp.expect((select count(*) from public.products
                       where establishment_id = 'aaaaaaaa-0000-0000-0000-0000000000e1'),
                      0, 'явный запрос к чужому заведению возвращает пусто');
end $prf$;

\echo ''
\echo '3. Разделение ролей: сотрудник и управляющий'

do $prf$ begin
  perform pg_temp.login('22222222-2222-2222-2222-222222222222');
end $prf$;

do $prf$ begin
  perform pg_temp.expect((select count(*) from public.products),
                      1, 'сотрудник читает справочник своего заведения');
end $prf$;

do $prf$ begin
  perform pg_temp.expect_denied(
  $q$ insert into public.products (id, establishment_id, name)
      values (gen_random_uuid(), 'aaaaaaaa-0000-0000-0000-0000000000e1', 'Самовольный товар') $q$,
  'сотрудник не может завести товар');
end $prf$;

do $prf$ begin
  perform pg_temp.expect_no_effect(
  $q$ update public.products set name = 'Переименовано'
      where id = 'aaaaaaaa-0000-0000-0000-0000000000c1' $q$,
  'сотрудник не может переименовать товар');
end $prf$;

-- А вот закрыть смену он обязан уметь: это его работа.
insert into public.shifts (id, establishment_id, closed_at, revenue_minor, cash_minor)
values ('aaaaaaaa-0000-0000-0000-0000000000f1',
        'aaaaaaaa-0000-0000-0000-0000000000e1', now(), 12345650, 12345650);

do $prf$ begin
  perform pg_temp.expect((select count(*) from public.shifts),
                      1, 'сотрудник закрывает смену');
end $prf$;

do $prf$ begin
  perform pg_temp.expect_no_effect(
  $q$ update public.shifts set revenue_minor = 999
      where id = 'aaaaaaaa-0000-0000-0000-0000000000f1' $q$,
  'сотрудник не может править закрытую смену задним числом');
end $prf$;

-- И убеждаемся, что значение действительно осталось прежним.
do $prf$ begin
  perform pg_temp.expect((select revenue_minor from public.shifts
                       where id = 'aaaaaaaa-0000-0000-0000-0000000000f1'),
                      12345650, 'сумма смены не изменилась после попытки правки');
end $prf$;

\echo ''
\echo '4. Управляющий правит смену'

do $prf$ begin
  perform pg_temp.login('11111111-1111-1111-1111-111111111111');
end $prf$;
update public.shifts set revenue_minor = 12300000
  where id = 'aaaaaaaa-0000-0000-0000-0000000000f1';
do $prf$ begin
  perform pg_temp.expect((select revenue_minor from public.shifts
                       where id = 'aaaaaaaa-0000-0000-0000-0000000000f1'),
                      12300000, 'владелец исправляет закрытую смену');
end $prf$;

do $prf$ begin
  perform pg_temp.expect((select count(*) from public.shifts
                       where establishment_id = 'bbbbbbbb-0000-0000-0000-0000000000e1'),
                      0, 'смены чужого заведения не видны');
end $prf$;

\echo ''
\echo '5. Идемпотентность повторной отправки'

-- Тот же id, что уже есть: повторная отправка из очереди синхронизации
-- не должна создать вторую смену и удвоить выручку.
insert into public.shifts (id, establishment_id, closed_at, revenue_minor)
values ('aaaaaaaa-0000-0000-0000-0000000000f1',
        'aaaaaaaa-0000-0000-0000-0000000000e1', now(), 99999)
on conflict (id) do nothing;

do $prf$ begin
  perform pg_temp.expect((select count(*) from public.shifts),
                      1, 'повторная отправка смены не создаёт дубль');
end $prf$;
do $prf$ begin
  perform pg_temp.expect((select revenue_minor from public.shifts
                       where id = 'aaaaaaaa-0000-0000-0000-0000000000f1'),
                      12300000, 'повтор не перезаписал сумму');
end $prf$;

\echo ''
\echo '6. Ключ iiko недоступен клиенту'

reset role;
insert into public.iiko_integrations (establishment_id, api_login_enc, organization_name)
values ('aaaaaaaa-0000-0000-0000-0000000000e1',
        pgp_sym_encrypt('секретный-ключ-iiko', 'тестовый-пароль'), 'Кофейня А');

set role authenticated;
do $prf$ begin
  perform pg_temp.login('11111111-1111-1111-1111-111111111111');
end $prf$;

do $prf$ begin
  perform pg_temp.expect_denied(
  $q$ select api_login_enc from public.iiko_integrations $q$,
  'ключ iiko не читается даже владельцем');
end $prf$;

do $prf$ begin
  perform pg_temp.expect_denied(
  $q$ select * from public.iiko_integrations $q$,
  'select * по таблице интеграции отклоняется');
end $prf$;

do $prf$ begin
  perform pg_temp.expect((select count(*) from public.iiko_status),
                      1, 'состояние интеграции читается без ключа');
end $prf$;

\echo ''
\echo '7. Метку времени ставит сервер'

reset role;
update public.products set updated_at = '2000-01-01'
  where id = 'bbbbbbbb-0000-0000-0000-0000000000c1';
do $prf$ begin
  perform pg_temp.expect(
  (select case when updated_at > now() - interval '1 minute' then 1 else 0 end
   from public.products where id = 'bbbbbbbb-0000-0000-0000-0000000000c1'),
  1, 'клиентское значение updated_at перезаписывается серверным');
end $prf$;

\echo ''
\echo '8. Ограничения целостности'

do $prf$ begin
  perform pg_temp.expect_denied(
  $q$ insert into public.shifts (id, establishment_id, closed_at, revenue_minor)
      values (gen_random_uuid(), 'aaaaaaaa-0000-0000-0000-0000000000e1', now(), -100) $q$,
  'отрицательная выручка отклоняется');
end $prf$;

do $prf$ begin
  perform pg_temp.expect_denied(
  $q$ insert into public.reminders (establishment_id, title, frequency, hour, minute)
      values ('aaaaaaaa-0000-0000-0000-0000000000e1', 'Без дня недели', 'weekly', 9, 0) $q$,
  'еженедельное напоминание без дня недели отклоняется');
end $prf$;

do $prf$ begin
  perform pg_temp.expect_denied(
  $q$ insert into public.products (id, establishment_id, name)
      values (gen_random_uuid(), 'aaaaaaaa-0000-0000-0000-0000000000e1', '   ') $q$,
  'товар с пустым названием отклоняется');
end $prf$;

\echo ''
\echo 'Все проверки пройдены.'
\echo ''
