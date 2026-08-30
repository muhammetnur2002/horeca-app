-- Демонстрационные данные для локальной разработки.
-- На боевую базу не применяется.

insert into auth.users (id, email)
values ('00000000-0000-0000-0000-0000000000aa', 'owner@akyl.local')
on conflict do nothing;

insert into public.organizations (id, name)
values ('00000000-0000-0000-0000-0000000000b0', 'Демо-организация')
on conflict do nothing;

insert into public.establishments (id, org_id, name, currency, timezone)
values ('00000000-0000-0000-0000-0000000000e0',
        '00000000-0000-0000-0000-0000000000b0', 'Демо-кофейня', '₸', 'Asia/Almaty')
on conflict do nothing;

insert into public.memberships (user_id, org_id, establishment_id, role)
values ('00000000-0000-0000-0000-0000000000aa',
        '00000000-0000-0000-0000-0000000000b0', null, 'owner')
on conflict do nothing;

with dept as (
  insert into public.departments (establishment_id, name, icon_key, sort_order)
  values ('00000000-0000-0000-0000-0000000000e0', 'Кухня', 'kitchen',    1),
         ('00000000-0000-0000-0000-0000000000e0', 'Бар',   'local_bar',  2),
         ('00000000-0000-0000-0000-0000000000e0', 'Зал',   'table_restaurant', 3)
  returning id, name
), cat as (
  insert into public.categories (establishment_id, department_id, name)
  select '00000000-0000-0000-0000-0000000000e0', d.id, c.name
  from dept d
  cross join lateral (
    select unnest(case d.name
      when 'Кухня' then array['Продукты', 'Заморозка']
      when 'Бар'   then array['Кофе', 'Сиропы']
      else array['Упаковка']
    end) as name
  ) c
  returning id, name
)
insert into public.products (establishment_id, category_id, name, unit, inventory_unit, min_stock)
select '00000000-0000-0000-0000-0000000000e0', c.id, p.name, p.unit, p.unit, p.min_stock
from cat c
cross join lateral (
  select * from (values
    ('Кофе',     'Кофе зерновой', 'кг', 2.0),
    ('Кофе',     'Молоко',        'л',  5.0),
    ('Сиропы',   'Сироп карамель','мл', 200.0),
    ('Продукты', 'Томаты',        'кг', 3.0),
    ('Продукты', 'Сыр',           'кг', 1.5),
    ('Заморозка','Овощи',         'упак', 4.0),
    ('Упаковка', 'Стаканы 0.3',   'шт', 100.0)
  ) v(cat_name, name, unit, min_stock)
  where v.cat_name = c.name
) p;

insert into public.staff_members (establishment_id, full_name)
values ('00000000-0000-0000-0000-0000000000e0', 'Бариста 1'),
       ('00000000-0000-0000-0000-0000000000e0', 'Бариста 2');
