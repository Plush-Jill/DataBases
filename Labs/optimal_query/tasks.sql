
create table providers (
    provider_id serial primary key,
    name varchar not null unique
);

create table products(
    product_id serial primary key,
    name varchar not null unique,
    price int not null
);

create table supplies(
    supply_id serial primary key,
    provider_id int references providers(provider_id),
    product_id int references products (product_id)
);

-- 1. Написать оптимальный запрос,
-- выбирающий поставщиков самых дорогих продуктов среди тех, которые поставляют продукты, начинающиеся на букву "А".
-- Таблицы: Поставщики (ПС, ПС_Название), Поставки (ID, ПС, ПР, Дата), Продукты (ПР, ПР_Название, Цена).
-- то есть: выбрать нужно сначала только тех, у кого есть продукты на букву А, затем

with max_a_begin_product_price as (
    select max(price) as max_price
    from products
    where products.name like 'A%'
),
max_provider_product_price as (
    select distinct
        supplies.provider_id as provider_id,
        max(products.price) over (partition by supplies.provider_id) as max_product_price
    from supplies
    join products on products.product_id = supplies.product_id
),
has_A_begin_product as(
    select
    providers.provider_id as provider_id,
    exists (
        select 1
        from supplies supplies_
        join products on supplies_.product_id = products.product_id
        where products.name like 'A%' and supplies_.provider_id = providers.provider_id
    ) as has_product_starting_with_A
    from providers
)
select
    providers.provider_id,
    providers.name
from providers
    join has_A_begin_product on has_A_begin_product.provider_id = providers.provider_id
    join max_provider_product_price on providers.provider_id = max_provider_product_price.provider_id




-- 1.

with max_provider_product_price_who_sell_A_begin_products as (
    select distinct
        supplies.provider_id as provider_id,
        max(products.price) over (partition by supplies.provider_id) as max_product_price
    from supplies
    join products on products.product_id = supplies.product_id
    where products.name like 'A%'
)

select distinct
    max_price_who_sell_A.provider_id,
    max_price_who_sell_A.max_product_price
from max_provider_product_price_who_sell_A_begin_products max_price_who_sell_A
order by max_price_who_sell_A.max_product_price desc
limit :defined_limit



-- 4.
with surnames_two_or_more as (
    select
        Surname
    from Students
    group by Surname
    having count(*) >= 2
)
select Students.StudentID
from Students
where surname in (select Surname from surnames_two_or_more);


-- 2. Выберите 3 лучших группы (по показателю avg_mark у студентов этой группы) по каждому из годов.
-- При этом для расчёта эффективности групп (среднего - avg_mark) используйте 30% случайных записей таблицы Performance.

-- Таблицы: Performance(StudentID, SubjectID, Date, Mark); Students(StudentID, Faculty, Surname, Name, Group).

with random_group_performance as (
    -- Случайный выбор 30% записей
    select distinct
        Students.Group as group_,
        extract(year from Performance.Date) as year_,
        avg(Performance.Mark) as average_mark_
    from Performance
    join Students on Performance.StudentID = Students.StudentID
    where random() <= 0.3
    group by Students.Group, year_
),
select
    group_,
    year_,
    average_mark_
from random_group_performance
order by year, average_mark
limit 3;


-- 3. Выберите 3 лучших учащихся в рамках каждого квартала,
-- где лучший учащийся - тот, у кого по максимальному количеству предметов стоит оценка 5
-- (если он получил 5 по одному предмету много раз, она считается за одну).
-- Таблицы: Performance(StudentID, SubjectID, Date, Mark); Students(StudentID, Faculty, Surname, Name, Group).

with students_quarter_performance as (
    -- Случайный выбор 30% записей
    select distinct
        Performance.StudentID as student_id_,
        extract(year from Performance.Date) as year_,
        extract(quarter from Performance.Date) as quarter_,
        count(distinct Performance.Mark) as excellent_mark_count_
    from Performance
    where Performance.Mark = 5
    group by Performance.StudentID, year_, quarter_
),
select
    student_id_,
    year_,
    quarter_,
    excellent_mark_count_
from students_quarter_performance
order by quarter_, average_mark
limit 3;

