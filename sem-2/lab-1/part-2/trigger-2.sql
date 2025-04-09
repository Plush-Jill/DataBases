-- 2.	Написать триггер, проверяющий, верно ли в таблице расписаний стоит время при внесении новых данных (новой строки):
-- оно должно быть больше времени, стоящего для предыдущей (в соответствии с маршрутом) станции данного поезда.
-- Если текущее время меньше предыдущего триггер должен автоматически сделать текущее время больше предыдущего на заданный интервал.
-- Интервал ищется триггером автоматически путём поиска оного у других поездов, передвигающихся между этими же двумя точками.
-- Если таковых нет, интервал берётся дефолтный (константа).



drop type if exists schedule_ex cascade;
create type schedule_ex as (
    id int,
    route_struct int,
    thread_id int,
    number int,
    departure_time timestamp,
    arrival_time timestamp
);

create or replace function find_correct_interval(cur_rs routes_details, check_s schedule_ex)
    returns interval as $$
declare
    correct_s schedule_time[];
begin
    select array (
        select row(schedule_time.*)
        from schedule_time
            inner join routes_details on schedule_time.station = routes_details.id
        where routes_details.route = cur_rs.route
            and (routes_details.station_order = cur_rs.station_order or routes_details.station_order = check_s.number)
            and schedule_time.trip != check_s.thread_id
        order by routes_details.station_order
    ) into correct_s;

    if (array_length(correct_s, 1) != 2) then
        return null;
    end if;

    return (correct_s[2]::schedule_time).arrival_time - (correct_s[1]::schedule_time).departure_time;
end;
$$ language plpgsql;

create or replace procedure shift_schedule_forward(check_schedule schedule_ex, default_move_interval interval, default_stop_time interval) as $$
declare
    move_interval interval := default_move_interval;
    stop_interval interval := default_stop_time;

    cur_schedule schedule_ex := check_schedule;
    next_schedule schedule_ex := null;
    cur_rs routes_details%rowtype;
    correct_interval interval;
begin
    while cur_schedule.id is not null loop
        select
            schedule_time.id,
            schedule_time.station,
            schedule_time.trip,
            routes_details.station_order,
            schedule_time.departure_time,
            schedule_time.arrival_time
                into next_schedule
        from schedule_time
            inner join routes_details on schedule_time.station = routes_details.id
        where schedule_time.trip = cur_schedule.thread_id and routes_details.station_order = cur_schedule.number + 1;

        select routes_details.*
        into cur_rs
        from routes_details
        where routes_details.id = cur_schedule.route_struct;
        if next_schedule is not null and next_schedule.arrival_time is not null then
            if cur_schedule.departure_time >= next_schedule.arrival_time then
                select * into correct_interval from find_correct_interval(cur_rs, next_schedule);
                if correct_interval is null then correct_interval = move_interval; end if;
                update schedule_time set
                                      arrival_time = cur_schedule.departure_time + correct_interval,
                                      departure_time = cur_schedule.departure_time + correct_interval + stop_interval
                where schedule_time.id = next_schedule.id;
                next_schedule.arrival_time := cur_schedule.departure_time + correct_interval;
                next_schedule.departure_time := cur_schedule.departure_time + correct_interval + stop_interval;
            end if;
        end if;
        cur_schedule := next_schedule;
    end loop;
end;
$$ language plpgsql;

create or replace function check_schedule() returns trigger as $$
declare
    default_move_interval constant interval := interval '1 hour';
    default_stop_interval constant interval := interval '10 minutes';

    new_s schedule_time%rowtype;
    first_rs routes_details%rowtype;
    cur_rs routes_details%rowtype;
    last_rs routes_details%rowtype;

    schedule_list schedule_ex[];
    prev_schedule schedule_ex;
    next_schedule schedule_ex;
    correct_interval interval;
    stop_interval interval;
begin
    new_s := new;
    stop_interval := default_stop_interval;
    select rs.* into cur_rs from routes_details rs where rs.id = new_s.station;
    select rs.* into first_rs from routes_details rs where route = cur_rs.route
    order by rs.station_order
    limit 1;
    select rs.* into last_rs from routes_details rs where route = cur_rs.route
    order by rs.station_order desc
    limit 1;

    if cur_rs.station_order = first_rs.station_order then
        if (new_s.departure_time is null or new_s.arrival_time is not null) then
            raise exception 'at first station departure_time should be null and arrival_time should not be null';
        end if;
    elseif cur_rs.station_order = last_rs.station_order then
        if (new_s.departure_time is not null or new_s.arrival_time is null) then
            raise exception 'at last station departure_time should be not null and arrival_time should be null';
        end if;
    else
        if (new_s.departure_time is null or new_s.arrival_time is null) then
            raise exception 'at middle station departure_time should be not null and arrival_time should not be null';
        end if;
        if (new_s.arrival_time >= new_s.departure_time) then
            raise exception 'departure_time should be greater then arrival_time';
        end if;
        stop_interval := new_s.departure_time - new_s.arrival_time;
    end if;

    select array(
        select row(schedule_time.id, schedule_time.station, schedule_time.trip, rs.station_order, schedule_time.departure_time, schedule_time.arrival_time)
        from schedule_time inner join routes_details rs on schedule_time.station = rs.id
        where schedule_time.trip = new.thread_id
        order by rs.station_order
    ) into schedule_list;

    if array_length(schedule_list, 1) = 0 then
        return new;
    end if;

    select
        schedule_time.id,
        schedule_time.station,
        schedule_time.trip,
        rs.station_order,
        schedule_time.departure_time,
        schedule_time.arrival_time
            into prev_schedule
    from schedule_time
        inner join routes_details rs on schedule_time.station = rs.id
    where schedule_time.trip = new_s.trip and rs.station_order = cur_rs.station_order - 1;

    if prev_schedule.departure_time is not null then
        if prev_schedule.departure_time >= new_s.arrival_time then
            select * into correct_interval from find_correct_interval(cur_rs, prev_schedule);
            if correct_interval is null then correct_interval = default_move_interval; end if;
            new_s.arrival_time := prev_schedule.departure_time + correct_interval;
            new_s.departure_time := prev_schedule.departure_time + correct_interval + stop_interval;
            call shift_schedule_forward(
                (new_s.id, new_s.station, new_s.trip, cur_rs.station_order, new_s.departure_time, new_s.arrival_time),
                default_move_interval,
                default_stop_interval
            );
        end if;
    end if;

    select
        schedule_time.id,
        schedule_time.station,
        schedule_time.trip,
        rs.station_order,
        schedule_time.departure_time,
        schedule_time.arrival_time
            into next_schedule
    from schedule_time
        inner join routes_details rs on schedule_time.station = rs.id
    where schedule_time.trip = new_s.trip and rs.station_order = cur_rs.station_order + 1;

    if next_schedule.arrival_time is not null then
        if new_s.departure_time >= next_schedule.arrival_time then
            call shift_schedule_forward(
                (new_s.id, new_s.station, new_s.trip, cur_rs.station_order, new_s.departure_time, new_s.arrival_time),
                default_move_interval,
                default_stop_interval
            );
        end if;
    end if;

    return new_s;
end
$$ language plpgsql;

create or replace trigger check_schedule_on_insert
    before insert on schedule_time
    for each row execute function check_schedule();
