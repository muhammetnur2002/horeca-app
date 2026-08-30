-- ─────────────────────────────────────────────────────────────────────────────
-- Справочники заведения: отделы, категории, товары, сотрудники.
--
-- Правило синхронизации для всех таблиц этого файла — «побеждает последний»
-- по серверному updated_at. Их правит только администратор, конфликты редки.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Отделы ───────────────────────────────────────────────────────────────────
create table public.departments (
  id                uuid        primary key default gen_random_uuid(),
  establishment_id  uuid        not null references public.establishments (id) on delete cascade,
  name              text        not null check (length(btrim(name)) between 1 and 120),
  icon_key          text        not null default 'category',
  sort_order        integer     not null default 0,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  deleted_at        timestamptz
);

comment on column public.departments.icon_key is
  'Строковый ключ иконки, а не числовой codePoint: динамический IconData ломает tree-shaking иконок в релизной сборке Flutter.';

-- ── Категории ────────────────────────────────────────────────────────────────
create table public.categories (
  id                uuid        primary key default gen_random_uuid(),
  establishment_id  uuid        not null references public.establishments (id) on delete cascade,
  department_id     uuid        references public.departments (id) on delete set null,
  name              text        not null check (length(btrim(name)) between 1 and 120),
  sort_order        integer     not null default 0,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  deleted_at        timestamptz
);

-- ── Товары ───────────────────────────────────────────────────────────────────
create table public.products (
  id                uuid          primary key default gen_random_uuid(),
  establishment_id  uuid          not null references public.establishments (id) on delete cascade,
  category_id       uuid          references public.categories (id) on delete set null,
  name              text          not null check (length(btrim(name)) between 1 and 200),
  unit              text          not null default 'шт' check (length(unit) between 1 and 24),
  inventory_unit    text          not null default 'шт' check (length(inventory_unit) between 1 and 24),
  min_stock         numeric(14,3) check (min_stock is null or min_stock >= 0),
  sort_order        integer       not null default 0,
  created_at        timestamptz   not null default now(),
  updated_at        timestamptz   not null default now(),
  deleted_at        timestamptz
);

comment on column public.products.inventory_unit is
  'Единица для инвентаризации может отличаться от единицы заказа: заказывают упаковками, считают штуками.';

-- ── Сотрудники смены ─────────────────────────────────────────────────────────
-- Это справочник имён для отметки «кто работал», а не учётные записи.
-- Аккаунты живут в auth.users и связываются через memberships.
create table public.staff_members (
  id                uuid        primary key default gen_random_uuid(),
  establishment_id  uuid        not null references public.establishments (id) on delete cascade,
  full_name         text        not null check (length(btrim(full_name)) between 1 and 200),
  is_active         boolean     not null default true,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  deleted_at        timestamptz
);

comment on table public.staff_members is
  'Справочник сотрудников для отметки смены. Не учётные записи — те в auth.users через memberships.';

-- ── Индексы под выборки и синхронизацию ──────────────────────────────────────
create index departments_est_idx    on public.departments   (establishment_id) where deleted_at is null;
create index categories_est_idx     on public.categories    (establishment_id) where deleted_at is null;
create index categories_dept_idx    on public.categories    (department_id)    where deleted_at is null;
create index products_est_idx       on public.products      (establishment_id) where deleted_at is null;
create index products_category_idx  on public.products      (category_id)      where deleted_at is null;
create index staff_est_idx          on public.staff_members (establishment_id) where deleted_at is null;

-- Основной индекс синхронизации: «всё, что изменилось в заведении после метки».
-- Включает удалённые строки — иначе клиент не узнает об удалении.
create index departments_sync_idx    on public.departments   (establishment_id, updated_at);
create index categories_sync_idx     on public.categories    (establishment_id, updated_at);
create index products_sync_idx       on public.products      (establishment_id, updated_at);
create index staff_sync_idx          on public.staff_members (establishment_id, updated_at);

select app.attach_sync_triggers('public.departments');
select app.attach_sync_triggers('public.categories');
select app.attach_sync_triggers('public.products');
select app.attach_sync_triggers('public.staff_members');
