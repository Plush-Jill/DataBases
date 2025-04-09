
drop table if exists employees cascade;
drop table if exists train_crew cascade;
drop table if exists booking cascade;
drop table if exists passengers cascade;
drop table if exists delay cascade;
drop table if exists carriages cascade;
drop table if exists trips cascade;
drop table if exists routes_details cascade;
drop table if exists carriages_category cascade;
drop table if exists routes cascade;
drop table if exists trains cascade;
drop table if exists stations cascade;
drop table if exists schedule_routes cascade;
drop table if exists schedule_time cascade;

drop type if exists train_category;
drop type if exists employee_position;


create type train_category as enum ('category-1', 'category-2', 'category-3');
create type employee_position as enum ('pos-1', 'pos-2', 'pos-3', 'pos-4', 'pos-5');

create table stations (
    id serial primary key,
    name varchar not null unique
);

create table routes (
    id serial primary key,
    number int null,
    name varchar not null unique,
    departure_station int references stations(id) not null,
    destination_station int references stations(id) not null
);

create table trains (
    id serial primary key,
    category train_category not null,
    head_station int references stations(id) not null
);

create table carriages_category (
    id serial primary key,
    name varchar(100) not null,
    schema jsonb
);

insert into carriages_category (name) values ('category-1'), ('category-2'), ('category-3');

create table routes_details (
    id serial primary key,
    route int references routes(id) on delete cascade not null,
    station int references stations(id) on delete cascade not null,
    station_order int not null,
    distance int not null,

    unique (route, station)
);


create table trips (
    id serial primary key,
    train int references trains(id) on delete set null,
    route int references routes(id) on delete cascade,
    trip_date date not null
);

create table carriages (
    id serial primary key,
    train int references trains(id) on delete set null,
    order_in_train int not null default 0,
    category int references carriages_category(id) on delete set null
);

create table schedule_time (
    id serial primary key,
    station int references routes_details(id),
    trip int references trips(id) on delete cascade not null,

    arrival_time timestamp,
    departure_time timestamp
);

create table delay (
    schedule_record int primary key references schedule_time(id) on delete cascade not null,
    arrival_delay interval not null default interval '0 second',
    departure_delay interval not null default '0 second'
);


create table passengers (
    id serial primary key,
    name varchar not null
);

create table booking (
    id serial primary key,
    carriage int references carriages(id) not null,
    place int not null,
    departure_station int references schedule_time(id) on delete cascade not null,
    destination_station int references schedule_time(id) on delete cascade not null check (departure_station != destination_station),
    passenger int references passengers(id) on delete cascade not null
);

create table employees (
    id int primary key,
    name varchar not null,
    position employee_position default 'pos-1'::employee_position,
    manager int default null,
    foreign key (manager) references employees("id") deferrable initially immediate
);


create table train_crew (
    employee int references employees(id) on delete set null not null,
    train int references trains(id) on delete cascade not null,
    setup_time timestamp not null default current_timestamp,
    remove_time timestamp
);

