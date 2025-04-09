-- 3.	Написать триггер для таблицы маршрутов, который автоматически ставит номер маршрута, если оный не заполнен при вставке данных.
-- Номер ставится по следующему правилу: минимальное число, которого нет ни в таблице маршрутов, ни в таблице расписания.

create or replace view ranked_route_numbers as
select
    routes.number as number
from schedule_time
    join routes_details on schedule_time.station = routes_details.id
    join routes on routes_details.route = routes.id

union distinct

select
    routes.number as number
from routes;


create or replace function check_route_id() returns trigger as $$
declare
    route_row routes%rowtype;
    new_route_number int;
begin
    route_row := new;
    if route_row.number is null then
        select free_row_number into new_route_number
        from (
            select
                ranked_route_numbers.number,
                rank() over (order by number) as free_row_number
            from ranked_route_numbers
        ) as ranked_route_numbers where free_row_number != ranked_route_numbers.number
        order by free_row_number
        limit 1;

        if new_route_number is null then
            new_route_number := nextval('trains_id_seq');
        end if;

        route_row.number = new_route_number;
        raise notice 'Found free route id: %', new_route_number;
    end if;

    return route_row;
end;
$$ language plpgsql;


create or replace trigger find_free_route_id_on_insert_trigger
before insert on routes
for each row execute function check_route_id();

delete from routes where name = 'name_';
delete from routes where number = 4;
delete from routes where id > 7;
-- alter sequence routes_id_seq restart with 6;

insert into routes (name, departure_station, destination_station)
values ('name_', 1, 4);
insert into routes (name, departure_station, destination_station)
values ('namee_', 2, 4);

select
    routes.id,
    routes.number,
    rank() over (order by id) as number_rank,
    routes.departure_station,
    routes.destination_station
from routes
order by id;

-- select
--     passengers.id,
--     rank() over (order by id) as id_rank
-- from passengers
-- order by id;
--
-- delete from passengers where id = 3

-- 4.	Написать триггер, который логирует (записывает все параметры в отдельную таблицу учёта)
-- все удаления поездов, на которых было продано более 300 билетов. В таблицу аудита надо бы записать и число удалённых билетов.
