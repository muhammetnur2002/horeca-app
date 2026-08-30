-- ─────────────────────────────────────────────────────────────────────────────
-- Напоминания, шаблоны выгрузки и интеграция с iiko.
-- ─────────────────────────────────────────────────────────────────────────────

do $$
begin
  if not exists (select 1 from pg_type where typname = 'reminder_frequency') then
    create type public.reminder_frequency as enum ('daily', 'weekly', 'monthly');
  end if;
end
$$;

-- ── Напоминания ──────────────────────────────────────────────────────────────
-- Само уведомление показывает устройство; сервер хранит только расписание,
-- чтобы оно пережило переустановку приложения и появилось на новом телефоне.
create table public.reminders (
  id                uuid        primary key default gen_random_uuid(),
  establishment_id  uuid        not null references public.establishments (id) on delete cascade,
  title             text        not null check (length(btrim(title)) between 1 and 200),
  frequency         public.reminder_frequency not null,
  hour              smallint    not null check (hour   between 0 and 23),
  minute            smallint    not null check (minute between 0 and 59),
  weekday           smallint    check (weekday      between 1 and 7),
  day_of_month      smallint    check (day_of_month between 1 and 31),
  is_enabled        boolean     not null default true,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  deleted_at        timestamptz,

  constraint reminders_weekday_required
    check (frequency <> 'weekly' or weekday is not null),
  constraint reminders_day_required
    check (frequency <> 'monthly' or day_of_month is not null)
);

comment on column public.reminders.day_of_month is
  'День 29–31 в коротком месяце прижимается к последнему дню — логика на клиенте.';

-- ── Шаблоны выгрузки инвентаризации ──────────────────────────────────────────
create table public.export_templates (
  id                uuid        primary key default gen_random_uuid(),
  establishment_id  uuid        not null references public.establishments (id) on delete cascade,
  name              text        not null check (length(btrim(name)) between 1 and 200),
  columns           jsonb       not null default '[]'::jsonb,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  deleted_at        timestamptz,

  constraint export_templates_columns_is_array
    check (jsonb_typeof(columns) = 'array')
);

comment on column public.export_templates.columns is
  'Соответствие колонок Excel полям инвентаризации: [{"header": "...", "field": "..."}].';

-- ── Интеграция с iiko ────────────────────────────────────────────────────────
-- Ключ доступа больше не хранится на устройстве. Приложение обращается
-- к своему API, а тот уже ходит в iiko: apiLogin в SharedPreferences
-- на каждом телефоне был прямым доступом к учётной системе заведения.
create table public.iiko_integrations (
  establishment_id   uuid        primary key references public.establishments (id) on delete cascade,
  api_login_enc      bytea       not null,
  organization_id    text,
  organization_name  text,
  store_ids          text[]      not null default '{}',
  last_sync_at       timestamptz,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

comment on column public.iiko_integrations.api_login_enc is
  'Ключ iiko в зашифрованном виде. Расшифровывается только серверной функцией — клиенту не отдаётся никогда.';

create index reminders_est_idx         on public.reminders        (establishment_id) where deleted_at is null;
create index reminders_sync_idx        on public.reminders        (establishment_id, updated_at);
create index export_templates_est_idx  on public.export_templates (establishment_id) where deleted_at is null;
create index export_templates_sync_idx on public.export_templates (establishment_id, updated_at);

select app.attach_sync_triggers('public.reminders');
select app.attach_sync_triggers('public.export_templates');
select app.attach_sync_triggers('public.iiko_integrations');
