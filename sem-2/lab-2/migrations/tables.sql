drop table if exists department_stores cascade;
drop table if exists department_stores_floors cascade;
drop table if exists department_stores_sections cascade;
drop table if exists department_stores_halls cascade;
drop table if exists department_stores_employees cascade;
drop table if exists department_stores_sections_managers cascade;
drop table if exists department_stores_sellers cascade;
drop table if exists shops cascade;
drop table if exists kiosks cascade;
drop table if exists stalls cascade;
drop table if exists shops cascade;
drop table if exists providers cascade;
drop table if exists product_directory cascade;
drop table if exists providers_product_list cascade;
drop table if exists users cascade;


create table users (
    id serial primary key,
    email varchar,
    password varchar,
    registration_date timestamp default now()
);
insert into users (email, password) values ('test@example.com', '123456');


-- Поставщики товаров
create table providers (
    id serial primary key,
    name varchar
);

-- Справочник номенклатуры товаров
create table product_directory (
    id serial primary key,
    name varchar not null
);

-- Список поставляемых поставщиками товаров
create table providers_product_list (
    provider int not null references providers(id),
    product int not null references product_directory(id),

    unique (provider, product)
);

-- Универмаги
create table department_stores (
    id serial primary key,
    name varchar
);

-- Этажи универмагов
create table department_stores_floors (
    id serial primary key,
    store int references department_stores(id) not null,
    floor int not null,

    unique (store, floor)
);

-- Универмаги разделены на отдельные секции, руководимые управляющими секций и расположенные, возможно, на разных этажах здания.
create table department_stores_sections (
    id serial primary key,
    section int not null references department_stores_floors(id),
    name varchar not null
);

-- Как универмаги, так и магазины могут иметь несколько залов, в которых работает определенное число продавцов
create table department_stores_halls (
    id serial primary key,
    place int not null references department_stores_sections(id)
);

-- Продавцы в универмагах
create table department_stores_sellers (
    id serial primary key,
    hall int not null references department_stores_halls(id)
);

-- Обычные работники
-- TODO: возможно, не нужна и стоит убрать
create table department_stores_employees (
    id serial primary key,
    name varchar not null,
    hall int not null references department_stores_halls(id)
);

-- TODO: тоже, возможно, не нужна и стоит убрать, оставить только departament_stores_sellers
create table department_stores_sections_managers (
    id serial primary key,
    section int not null references department_stores_sections(id),
    manager int not null references department_stores_employees(id)
);







create table shops (
    id serial primary key,
    name varchar
);

create table kiosks (
    id serial primary key,
    name varchar
);

create table stalls (
    id serial primary key,
    name varchar
);

