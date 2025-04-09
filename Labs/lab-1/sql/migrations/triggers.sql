/* -- 1 -- */
drop type if exists trr cascade;
create type trr as (
    t_train_id int,
    t_route_id int,
    s_route_id int
);
create or replace function check_train_on_route() returns trigger as $$
declare
    new_rcb railroads_cars_booking%rowtype;
    train_id int;
    trr_list trr[];
    i_trr trr;
begin
    new_rcb := new;
    select rc.train_id into train_id from railroad_cars rc
    where rc.id = new_rcb.railroad_car_id;
    select array (
        select row(t.train_id, t.route_id, rs.route_id)::trr from schedule s
            inner join threads t on s.thread_id = t.id
            inner join routes_structure rs on s.route_structure_id = rs.id
        where s.id = new_rcb.departure_point or s.id = new_rcb.arrival_point
    ) into trr_list;
    foreach i_trr in array trr_list loop
        if (i_trr.t_train_id != train_id or
            i_trr.t_route_id != (trr_list[0]::trr).t_route_id or
            i_trr.t_route_id != i_trr.s_route_id) then
            raise exception 'trains_id or route_id incorrect';
        end if;
    end loop;

    return new_rcb;
end;
$$ language plpgsql;

create or replace trigger check_train_on_route_on_insert
    before insert on railroads_cars_booking
    for each row execute function check_train_on_route();

/* -- 2 -- */
drop type if exists schedule_ex cascade;
create type schedule_ex as (
    id int,
    route_struct int,
    thread_id int,
    number int,
    departure_time timestamp,
    arrival_time timestamp
);

create or replace function find_correct_interval(cur_rs routes_structure, check_s schedule_ex)
    returns interval as $$
declare
    correct_s schedule[];
begin
    select array (
        select row(s.*) from schedule s inner join routes_structure rs on s.route_structure_id = rs.id
        where rs.route_id = cur_rs.route_id and (rs.station_number_in_route = cur_rs.station_number_in_route or rs.station_number_in_route = check_s.number)
                                            and s.thread_id != check_s.thread_id
        order by rs.station_number_in_route
    ) into correct_s;

    if (array_length(correct_s, 1) != 2) then
        return null;
    end if;

    return (correct_s[2]::schedule).arrival_time - (correct_s[1]::schedule).departure_time;
end;
$$ language plpgsql;

create or replace procedure shift_schedule_forward(check_schedule schedule_ex, default_move_interval interval, default_stop_time interval) as $$
declare
    move_interval interval := default_move_interval;
    stop_interval interval := default_stop_time;

    cur_schedule schedule_ex := check_schedule;
    next_schedule schedule_ex := null;
    cur_rs routes_structure%rowtype;
    correct_interval interval;
begin
    while cur_schedule.id is not null loop
        select s.id, s.route_structure_id, s.thread_id, rs.station_number_in_route,
               s.departure_time, s.arrival_time into next_schedule
        from schedule s inner join routes_structure rs on s.route_structure_id = rs.id
        where s.thread_id = cur_schedule.thread_id and rs.station_number_in_route = cur_schedule.number + 1;

        select rs.* into cur_rs from routes_structure rs
        where rs.id = cur_schedule.route_struct;
        if next_schedule is not null and next_schedule.arrival_time is not null then
            if cur_schedule.departure_time >= next_schedule.arrival_time then
                select * into correct_interval from find_correct_interval(cur_rs, next_schedule);
                if correct_interval is null then correct_interval = move_interval; end if;
                update schedule s set
                                      arrival_time = cur_schedule.departure_time + correct_interval,
                                      departure_time = cur_schedule.departure_time + correct_interval + stop_interval
                where s.id = next_schedule.id;
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

    new_s schedule%rowtype;
    first_rs routes_structure%rowtype;
    cur_rs routes_structure%rowtype;
    last_rs routes_structure%rowtype;

    schedule_list schedule_ex[];
    prev_schedule schedule_ex;
    next_schedule schedule_ex;
    correct_interval interval;
    stop_interval interval;
begin
    new_s := new;
    stop_interval := default_stop_interval;
    select rs.* into cur_rs from routes_structure rs where rs.id = new_s.route_structure_id;
    select rs.* into first_rs from routes_structure rs where route_id = cur_rs.route_id
    order by rs.station_number_in_route
    limit 1;
    select rs.* into last_rs from routes_structure rs where route_id = cur_rs.route_id
    order by rs.station_number_in_route desc
    limit 1;

    if cur_rs.station_number_in_route = first_rs.station_number_in_route then
        if (new_s.departure_time is null or new_s.arrival_time is not null) then
            raise exception 'at first station departure_time should be null and arrival_time should not be null';
        end if;
    elseif cur_rs.station_number_in_route = last_rs.station_number_in_route then
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
        select row(s.id, s.route_structure_id, s.thread_id, rs.station_number_in_route, s.departure_time, s.arrival_time)
        from schedule s inner join routes_structure rs on s.route_structure_id = rs.id
        where s.thread_id = new.thread_id
        order by rs.station_number_in_route
    ) into schedule_list;

    if array_length(schedule_list, 1) = 0 then
        return new;
    end if;

    select s.id, s.route_structure_id, s.thread_id, rs.station_number_in_route,
            s.departure_time, s.arrival_time into prev_schedule
    from schedule s inner join routes_structure rs on s.route_structure_id = rs.id
    where s.thread_id = new_s.thread_id and rs.station_number_in_route = cur_rs.station_number_in_route - 1;

    if prev_schedule.departure_time is not null then
        if prev_schedule.departure_time >= new_s.arrival_time then
            select * into correct_interval from find_correct_interval(cur_rs, prev_schedule);
            if correct_interval is null then correct_interval = default_move_interval; end if;
            new_s.arrival_time := prev_schedule.departure_time + correct_interval;
            new_s.departure_time := prev_schedule.departure_time + correct_interval + stop_interval;
            call shift_schedule_forward(
                (new_s.id, new_s.route_structure_id, new_s.thread_id, cur_rs.station_number_in_route, new_s.departure_time, new_s.arrival_time),
                default_move_interval,
                default_stop_interval
            );
        end if;
    end if;

    select s.id, s.route_structure_id, s.thread_id, rs.station_number_in_route,
           s.departure_time, s.arrival_time into next_schedule
    from schedule s inner join routes_structure rs on s.route_structure_id = rs.id
    where s.thread_id = new_s.thread_id and rs.station_number_in_route = cur_rs.station_number_in_route + 1;

    if next_schedule.arrival_time is not null then
        if new_s.departure_time >= next_schedule.arrival_time then
            call shift_schedule_forward(
                (new_s.id, new_s.route_structure_id, new_s.thread_id, cur_rs.station_number_in_route, new_s.departure_time, new_s.arrival_time),
                default_move_interval,
                default_stop_interval
            );
        end if;
    end if;

    return new_s;
end
$$ language plpgsql;

create or replace trigger check_schedule_on_insert
    before insert on schedule
    for each row execute function check_schedule();

/* -- 3 -- */
create or replace function set_free_route_number() returns trigger as $$
declare
    new_s schedule%rowtype;
    new_id int;
begin
    new_s := new;
    if new_s.id is null then
        select rown into new_id from (
            select id, rank() over (order by id desc) as rown from (
                select s.id as id from schedule s
                    union
                select r.id as id from routes r
            ) as id_rown
        ) where rown != id
        order by rown
        limit 1;

        raise notice '%', new_id;

        if new_id is null then
            new_id := nextval('"trains"."schedule_id_seq"');
        end if;
        new_s.id = new_id;
    end if;

    return new_s;
end;
$$ language plpgsql;

create or replace trigger set_free_route_number_on_insert
    before insert on schedule
    for each row execute function set_free_route_number();

/* -- 4 -- */
-- create table deleted_trains (like trains including all);
drop table if exists deleted_trains cascade;
create table deleted_trains (
    id int primary key generated by default as identity,
    category trains_category not null default 'c1'::trains_category,
    header_station int references stations(id) on delete set null,
    booking_count int
);
create or replace function log_train() returns trigger as $$
declare
    delete_t trains%rowtype;
    total_booking_count int;
    current_booking_count int;
begin
    delete_t := old;
    select count(*) into current_booking_count from
        (select t.id from trains t where t.id = delete_t.id) as tid
    inner join railroad_cars rc on tid = rc.train_id
    inner join railroads_cars_booking rcb on rc.id = rcb.railroad_car_id;
    if total_booking_count > 300 then
        insert into deleted_trains select *, total_booking_count from delete_t;
    end if;
    return delete_t;
end;
$$ language plpgsql;