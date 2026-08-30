-- ─────────────────────────────────────────────────────────────────────────────
-- Основание: расширения, служебная схема, общие типы и триггеры.
-- ─────────────────────────────────────────────────────────────────────────────

create extension if not exists pgcrypto;

-- Схема app — внутренняя кухня: функции для политик доступа и синхронизации.
-- Клиент к ней напрямую не обращается, поэтому она отделена от public.
create schema if not exists app;

comment on schema app is
  'Служебные функции: проверки доступа для RLS и синхронизация. Не является публичным API.';

-- ── Роли участников ──────────────────────────────────────────────────────────
do $$
begin
  if not exists (select 1 from pg_type where typname = 'member_role') then
    create type public.member_role as enum ('owner', 'manager', 'staff');
  end if;
end
$$;

comment on type public.member_role is
  'owner — владелец организации; manager — управляющий точкой; staff — сотрудник смены.';

-- ── Отметка времени изменения ────────────────────────────────────────────────
-- updated_at проставляет сервер, а не клиент: часы на устройствах врут,
-- и синхронизация по клиентскому времени тихо теряет записи.
create or replace function app.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

comment on function app.touch_updated_at() is
  'Триггер: обновляет updated_at серверным временем при каждом изменении строки.';

-- Навешивает стандартные триггеры на синхронизируемую таблицу.
create or replace function app.attach_sync_triggers(p_table regclass)
returns void
language plpgsql
as $$
declare
  v_name text := replace(p_table::text, '.', '_');
begin
  execute format(
    'create trigger %I before update on %s
       for each row execute function app.touch_updated_at()',
    'trg_' || v_name || '_touch', p_table
  );
end;
$$;
