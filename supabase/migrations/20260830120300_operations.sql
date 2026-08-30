-- ─────────────────────────────────────────────────────────────────────────────
-- Операции: закрытые смены, заявки, инвентаризации, остатки.
--
-- Правило синхронизации для этого файла — «только добавление».
-- Закрытая смена это факт, а не изменяемая строка: версии с двух устройств
-- никогда не сливаются. Идемпотентность обеспечивает первичный ключ —
-- id генерирует клиент, повторная отправка гасится через on conflict do nothing.
--
-- Все денежные суммы — целые в минорных единицах (тиыны, копейки).
-- Ни numeric, ни тем более float: одна единица измерения на всю систему
-- избавляет от расхождений в отчётах.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Закрытые смены ───────────────────────────────────────────────────────────
create table public.shifts (
  id                  uuid        primary key,
  establishment_id    uuid        not null references public.establishments (id) on delete cascade,
  closed_at           timestamptz not null,
  closed_by           uuid        references auth.users (id) on delete set null,
  staff_names         text[]      not null default '{}',

  revenue_minor       bigint      not null default 0 check (revenue_minor      >= 0),
  qr_minor            bigint      not null default 0 check (qr_minor           >= 0),
  card_minor          bigint      not null default 0 check (card_minor         >= 0),
  cash_minor          bigint      not null default 0 check (cash_minor         >= 0),
  morning_cash_minor  bigint      not null default 0 check (morning_cash_minor >= 0),
  evening_cash_minor  bigint      not null default 0 check (evening_cash_minor >= 0),
  inkass_minor        bigint      not null default 0 check (inkass_minor       >= 0),

  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz
);

comment on column public.shifts.id is
  'UUID генерирует клиент. Он же ключ идемпотентности: повторная отправка той же смены не создаёт дубль.';
comment on column public.shifts.revenue_minor is
  'Итоговая выручка в минорных единицах валюты заведения.';

create table public.shift_writeoffs (
  id            uuid          primary key,
  shift_id      uuid          not null references public.shifts (id) on delete cascade,
  product_name  text          not null check (length(btrim(product_name)) between 1 and 200),
  quantity      numeric(14,3) not null check (quantity > 0),
  unit          text          not null default 'шт',
  created_at    timestamptz   not null default now()
);

comment on column public.shift_writeoffs.product_name is
  'Название на момент списания, а не ссылка на товар: переименование или удаление товара не должно менять уже закрытую смену.';

-- ── Заявки на закупку ────────────────────────────────────────────────────────
create table public.requests (
  id                uuid        primary key,
  establishment_id  uuid        not null references public.establishments (id) on delete cascade,
  department_id     uuid        references public.departments (id) on delete set null,
  department_name   text        not null default '',
  created_by        uuid        references auth.users (id) on delete set null,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  deleted_at        timestamptz
);

create table public.request_items (
  id            uuid          primary key,
  request_id    uuid          not null references public.requests (id) on delete cascade,
  product_id    uuid          references public.products (id) on delete set null,
  product_name  text          not null check (length(btrim(product_name)) between 1 and 200),
  quantity      numeric(14,3) not null check (quantity > 0),
  unit          text          not null default 'шт',
  comment       text
);

-- ── Инвентаризации ───────────────────────────────────────────────────────────
create table public.inventories (
  id                uuid        primary key,
  establishment_id  uuid        not null references public.establishments (id) on delete cascade,
  department_id     uuid        references public.departments (id) on delete set null,
  department_name   text        not null default '',
  created_by        uuid        references auth.users (id) on delete set null,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  deleted_at        timestamptz
);

create table public.inventory_items (
  id            uuid          primary key,
  inventory_id  uuid          not null references public.inventories (id) on delete cascade,
  product_id    uuid          references public.products (id) on delete set null,
  product_name  text          not null check (length(btrim(product_name)) between 1 and 200),
  remaining     numeric(14,3) not null check (remaining >= 0),
  unit          text          not null default 'шт'
);

-- ── Текущие остатки ──────────────────────────────────────────────────────────
-- Единственная таблица операций, которая изменяется. Правило разрешения
-- конфликтов своё: побеждает более позднее измерение по measured_at.
create table public.stock_levels (
  establishment_id  uuid          not null references public.establishments (id) on delete cascade,
  product_id        uuid          not null references public.products (id) on delete cascade,
  remaining         numeric(14,3) not null check (remaining >= 0),
  measured_at       timestamptz   not null,
  updated_at        timestamptz   not null default now(),
  primary key (establishment_id, product_id)
);

comment on table public.stock_levels is
  'Последний известный остаток по товару. При конфликте побеждает запись с более поздним measured_at.';

-- ── Индексы ──────────────────────────────────────────────────────────────────
create index shifts_est_closed_idx      on public.shifts          (establishment_id, closed_at desc);
create index shifts_sync_idx            on public.shifts          (establishment_id, updated_at);
create index shift_writeoffs_shift_idx  on public.shift_writeoffs (shift_id);

create index requests_est_idx           on public.requests        (establishment_id, created_at desc);
create index requests_sync_idx          on public.requests        (establishment_id, updated_at);
create index request_items_request_idx  on public.request_items   (request_id);

create index inventories_est_idx        on public.inventories     (establishment_id, created_at desc);
create index inventories_sync_idx       on public.inventories     (establishment_id, updated_at);
create index inventory_items_inv_idx    on public.inventory_items (inventory_id);

create index stock_levels_sync_idx      on public.stock_levels    (establishment_id, updated_at);

select app.attach_sync_triggers('public.shifts');
select app.attach_sync_triggers('public.requests');
select app.attach_sync_triggers('public.inventories');
select app.attach_sync_triggers('public.stock_levels');
