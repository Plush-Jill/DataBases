--
-- -- Отчёты о маршрутах и поездах между указанными городами (без привязки к датам/расписанию).
-- select
--     trains.id      as train_id,
--     s1.city        as departure_station_city,
--     s1.id          as departure_station_id,
--     s1.city        as destination_station_city,
--     s1.id          as destination_station_id
-- from trains
--     join routes r1 on trains.id = r1.train_id
-- --     join routes r2 on trains.id = r2.train_id
--     join stations s1 on r1.station_id = s1.id
-- --     join stations s2 on r2.station_id = s2.id
-- where
--     s1.city = :departure_city
--     and s1.city = :destination_city
-- --     and r1.station_order < r2.station_order
-- order by
--     trains.id;
--
--
-- -- 6)
-- -- Сотрудники РЖД с иерархией (у каждого сотрудника есть непосредственный рук-ль, у него – свой и т.д., у владельца бизнеса рук-ля нет).
--
-- with recursive employee_hierarchy as (
--     select
--         id,
--         position,
--         supervisor_id,
--         cast(id as varchar) as path,
--         lpad('', 0, ' ') || employees.surname || ' ' || employees.name || ' ' || coalesce(employees.patronymic, '') as full_name,
--         1 as level
--     from employees
--     where supervisor_id is null
--
--     union
--
--     select employees.id,
--         employees.position,
--         employees.supervisor_id,
--         cast(eh.path || '=>' || employees.id as varchar) as path,
--         lpad('', (eh.level) * 4, ' ') || employees.surname || ' ' || employees.name || ' ' || coalesce(employees.patronymic, '') as full_name,
--         eh.level + 1
--     from employees
--         join employee_hierarchy eh on employees.supervisor_id = eh.id)
-- select
--     id,
--     full_name,
--     position,
--     supervisor_id,
--     path
-- from employee_hierarchy
-- order by path;
--
--
--
-- -- Все станции-пересадки по маршруту между двумя станциями (от заданной до заданной)
--
-- with defined_stations_stop_orders as (
--     select
--         route_stations.route_id,
--         array_agg(route_stations.stop_order) as stop_orders
--     from route_stations
--     where route_stations.station_id in (:departure_station, :destination_station)
--     group by route_stations.route_id
--     having count(distinct route_stations.station_id) = 2
-- )
-- select
--     route_stations.station_id,
--     route_stations.stop_order
-- from route_stations
-- join stations s on route_stations.station_id = s.id
-- join defined_stations_stop_orders stop_orders on route_stations.route_id = defined_stations_stop_orders.route_id
-- where
--     route_stations.stop_order > least(stop_orders.stop_orders[1], stop_orders.stop_orders[2])
--     and route_stations.stop_order < greatest(stop_orders.stop_orders[1], stop_orders.stop_orders[2])
-- order by
--     route_stations.route_id, route_stations.stop_order;
--
--
--
-- select
--     id,
--     passport_data,
--     LAG(passport_data) OVER (ORDER BY passport_data DESC) AS previous_mark,
--     LEAD(passport_data) OVER (ORDER BY passport_data DESC) AS next_mark
-- from passengers;
--
-- select distinct
--     route_id,
--     sum(stop_order) over (partition by route_id) as stop_order_sum
-- from route_stations
-- order by route_id;
--
--
--
--
--
--











-- Отчёт о едущих ближайших поездах в указанный город в указанный отрезок времени
-- с указанием дат-времён отправления из начальной точки и прибытия в конечную точку.

select
    schedule_routes.train_id,
    min(schedule_time.planned_arrival_time) AS first_station_arrival_time,
    max(schedule_time.planned_arrival_time) AS last_station_arrival_time
from stations
join schedule_time on stations.id = schedule_time.station_id
join schedule_routes on schedule_time.schedule_id = schedule_routes.id
where
    stations.city = :city
    and schedule_time.planned_arrival_time between :time_interval_begin and :time_interval_end
group by schedule_routes.train_id;




-- Количество билетов на указанный поезд (от заданного города до заданного в указанный промежуток времени) с заданным типом мест (плацкарт/купе/СВ).

select
    min(seats.free_seats) as min_free_seats
from free_seats seats
join schedule_routes on seats.schedule_id = schedule_routes.id
join route_stations_order rso_departure on rso_departure.route_id = schedule_routes.route_id
join route_stations_order rso_destination on rso_destination.route_id = schedule_routes.route_id
join stations departure_station on departure_station.id = rso_departure.station_id
join stations destination_station on destination_station.id = rso_destination.station_id
join schedule_time time_departure on seats.schedule_id = time_departure.schedule_id
join schedule_time time_destination on seats.schedule_id = time_destination.schedule_id
where
    departure_station.city = :departure_station_city
    and destination_station.city = :destination_station_city
    and seats.seat_category = :seat_category
    and rso_departure.stop_order < rso_destination.stop_order
    and time_departure.planned_arrival_time > :start_time
    and time_destination.planned_arrival_time < :end_time
    and schedule_routes.train_id = :train_id;



insert into route_stations (route_id, station_id, stop_order) values
(2, 161, 9),
(2, 346, 10),
(2, 236, 11),
(2, 37, 12),
(2, 12, 13)
