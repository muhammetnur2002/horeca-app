-- ─────────────────────────────────────────────────────────────────────────────
-- Мультиарендность: организация → заведение → участник.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Организация — клиент SaaS и единица тарификации ──────────────────────────
create table public.organizations (
  id          uuid primary key default gen_random_uuid(),
  name        text        not null check (length(btrim(name)) between 1 and 200),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

comment on table public.organizations is
  'Клиент SaaS. Одна организация владеет одним или несколькими заведениями.';

-- ── Заведение — конкретная точка ─────────────────────────────────────────────
create table public.establishments (
  id          uuid primary key default gen_random_uuid(),
  org_id      uuid        not null references public.organizations (id) on delete cascade,
  name        text        not null check (length(btrim(name)) between 1 and 200),
  currency    text        not null default '₸' check (length(currency) between 1 and 8),
  timezone    text        not null default 'Asia/Almaty',
  logo_path   text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

comment on column public.establishments.timezone is
  'Часовой пояс точки в формате IANA. Определяет границы суток в отчётах и время напоминаний.';

create index establishments_org_idx on public.establishments (org_id) where deleted_at is null;

-- ── Участники ────────────────────────────────────────────────────────────────
-- establishment_id = null означает доступ ко всем точкам организации:
-- так владелец не теряет доступ при добавлении новой точки.
create table public.memberships (
  id                uuid        primary key default gen_random_uuid(),
  user_id           uuid        not null references auth.users (id) on delete cascade,
  org_id            uuid        not null references public.organizations (id) on delete cascade,
  establishment_id  uuid        references public.establishments (id) on delete cascade,
  role              public.member_role not null,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  deleted_at        timestamptz,

  -- nulls not distinct: иначе один и тот же пользователь мог бы получить
  -- несколько одинаковых доступов ко всей организации.
  constraint memberships_unique_grant
    unique nulls not distinct (user_id, org_id, establishment_id)
);

comment on column public.memberships.establishment_id is
  'null — доступ ко всем заведениям организации. Иначе доступ только к указанной точке.';

create index memberships_user_idx on public.memberships (user_id) where deleted_at is null;
create index memberships_org_idx  on public.memberships (org_id)  where deleted_at is null;

-- ── Функции доступа ──────────────────────────────────────────────────────────
-- security definer обязателен: политики на memberships сами обращаются
-- к memberships, и без обхода RLS это дало бы бесконечную рекурсию —
-- классическая ошибка на Supabase. search_path зафиксирован явно,
-- иначе security definer открывает подмену объектов.

create or replace function app.member_establishments()
returns table (establishment_id uuid, role public.member_role)
language sql
stable
security definer
set search_path = public, auth, pg_temp
as $$
  select e.id, m.role
  from public.establishments e
  join public.memberships   m on m.org_id = e.org_id
  where m.user_id = auth.uid()
    and m.deleted_at is null
    and e.deleted_at is null
    and (m.establishment_id is null or m.establishment_id = e.id);
$$;

comment on function app.member_establishments() is
  'Заведения, доступные текущему пользователю, вместе с его ролью в каждом.';

-- Есть ли у текущего пользователя доступ к заведению (любая роль).
create or replace function app.can_read(p_establishment uuid)
returns boolean
language sql
stable
security definer
set search_path = public, auth, pg_temp
as $$
  select exists (
    select 1 from app.member_establishments() me
    where me.establishment_id = p_establishment
  );
$$;

-- Может ли текущий пользователь править справочники и настройки заведения.
create or replace function app.can_manage(p_establishment uuid)
returns boolean
language sql
stable
security definer
set search_path = public, auth, pg_temp
as $$
  select exists (
    select 1 from app.member_establishments() me
    where me.establishment_id = p_establishment
      and me.role in ('owner', 'manager')
  );
$$;

comment on function app.can_manage(uuid) is
  'Право на изменение справочников. Сотрудник смены (staff) его не имеет.';

-- Владелец организации. Отдельная функция, потому что политики на memberships
-- обращаются к самой memberships — без обхода RLS это бесконечная рекурсия.
create or replace function app.is_org_owner(p_org uuid)
returns boolean
language sql
stable
security definer
set search_path = public, auth, pg_temp
as $$
  select exists (
    select 1 from public.memberships m
    where m.org_id = p_org
      and m.user_id = auth.uid()
      and m.role = 'owner'
      and m.deleted_at is null
  );
$$;

select app.attach_sync_triggers('public.organizations');
select app.attach_sync_triggers('public.establishments');
select app.attach_sync_triggers('public.memberships');
