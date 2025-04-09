
create type train_category as enum ('category-1', 'category-2');

create table stations (
    id serial primary key,
    name varchar,
    city varchar not null
);

create table trains (
    id serial,
    destination_station int references stations(id),
    departure_station int references stations(id),
    head_station int references stations(id),
    category train_category,

    primary key (id)
);

create table train_struct (
    train_number int primary key references trains(id),
    general_tickets_count int,
    reserved_tickets_count int,
    coupe_tickets_count int,
    suite_tickets_count int
);

create table routes (
    id serial primary key,
    departure_station int not null references stations(id),
    destination_station int not null references stations(id),

    unique (departure_station, destination_station)
);

create table route_stations_order(
    route_id int references routes(id),
    station_id int references stations(id),
    stop_order int,

    primary key (route_id, station_id),
    unique (route_id, station_id, stop_order)
);

create table schedule_routes(
    id serial unique,
    route_id int references routes(id),
    train_id int references trains(id)
);

create table schedule_time (
    schedule_id int references schedule_routes(id),
    station_id int references stations(id),

    planned_arrival_time timestamp(0),
    real_arrival_time timestamp(0),
    stop_duration interval
);


create table passengers (
    id serial primary key,
    name varchar not null,
    surname varchar not null,
    patronymic varchar,
    passport_data int unique not null
);

create type SeatCategory as enum ('reserved', 'coupe', 'suite');

create table passengers_trips (
    id serial primary key,
    passenger_id int references passengers(id),
    schedule_id int references schedule_routes(id),
    seat_category SeatCategory not null,

    departure_station int references stations(id),
    destination_station int references stations(id)
);

create type EmployeePosition as enum ('pos-1', 'pos-2', 'pos-3', 'pos-4', 'pos-5');

create table employees (
    id serial primary key,
    name varchar,
    surname varchar,
    patronymic varchar,
    position EmployeePosition,
    supervisor_id int references employees(id),
    city varchar,
    brigade int references trains(id)
);

create table free_seats (
    schedule_id int references schedule_routes(id), -- Конкретная поездка
    departure_station_id int references stations(id),         -- Станция маршрута
    destination_station_id int references stations(id),         -- Станция маршрута
    seat_category SeatCategory not null,            -- Категория мест
    free_seats int not null,                        -- Количество свободных мест
    primary key (schedule_id, departure_station_id, destination_station_id, seat_category)
);



-- create table occupied_seats (
--     id serial primary key,
--     schedule_id int references schedule_routes(id),
--     departure_station int references stations(id),
--     destination_station int references stations(id),
--     seat_category SeatCategory not null ,
--     occupied_count int not null -- Число занятых мест на данном участке
-- );
