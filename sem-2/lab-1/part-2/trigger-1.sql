-- 1.	Написать триггер, проверяющий,
-- корректные ли данные вносятся в timetable в части соответствия поезда и станции назначенному на данный поезд маршруту.



drop type if exists trr cascade;
create type trr as (
    t_train_id int,
    t_route_id int,
    s_route_id int
);

create or replace function check_train_on_route() returns trigger as $$
declare
    new_booking_row booking%rowtype;
    train_id int;
    trr_list trr[];
    i_trr trr;
begin
    new_booking_row := new;
    select carriages.train into train_id
    from carriages
    where carriages.id = new_booking_row.carriage;

    select array (
        select row(trips.train, trips.route, routes_details.route)::trr
        from schedule_time
            inner join trips on schedule_time.trip = trips.id
            inner join routes_details on schedule_time.id = routes_details.id
        where schedule_time.id = new_booking_row.departure_station or schedule_time.id = new_booking_row.destination_station
    ) into trr_list;
    foreach i_trr in array trr_list loop
        if (i_trr.t_train_id != train_id or
            i_trr.t_route_id != (trr_list[0]::trr).t_route_id or
            i_trr.t_route_id != i_trr.s_route_id) then
            raise exception 'trains_id or route_id incorrect';
        end if;
    end loop;

    return new_booking_row;
end;
$$ language plpgsql;

create or replace trigger check_train_on_route_on_insert
before insert on booking
for each row execute function check_train_on_route();