drop type if exists full_trip cascade;
create type full_trip as (
    pass_id int,
    thread_id int,
    departure_time timestamp,
    station_in_number_route int,
    distance int
);
drop type if exists aggregation_report cascade;
create type aggregation_report as (
    thread_count int,
    pass_count int,
    distance_sum int,
    calc_day date
);
drop type if exists uniq_arr;
create type uniq_arr as (
    passenger_arr integer[],
    thread_arr integer[]
);
drop type if exists tpd cascade;
create type tpd as (
    thread_count int,
    pass_count int,
    dist_sum int
);
drop type if exists accumulated_report;
create type accumulated_report as (
    thread_count int,
    pass_count int,
    dist_sum int,
    date varchar(100)
);
drop index if exists idx_schedule_thread;
drop index if exists idx_routes_structure_route;
drop index if exists idx_railroads_cars_booking_departure_arrival;
drop function if exists get_trip_report();
create index idx_schedule_thread ON schedule(thread);
create index idx_routes_structure_route ON routes_details(route);
create index idx_railroads_cars_booking_departure_arrival ON carriages_booking(departure_point, arrival_point);
create or replace function get_trip_report() returns accumulated_report[] as $$
declare
    index int;
    index2 int;
    day date;
    day_list date[];
    rep aggregation_report;
    sum_by_days aggregation_report[];
    pass_append int := 0;
    thread_append int := 0;
    uniq_list uniq_arr[];

    i_trip full_trip;
    i_report aggregation_report;
    test_report aggregation_report;

    prev_report aggregation_report := null;
    tpd_day_sum tpd := (0, 0, 0, null);
    tpd_quarter_sum tpd := (0, 0, 0, null);
    tpd_year_sum tpd := (0, 0, 0, null);

    final_report accumulated_report[];
begin
    for i_trip in
        select rcb.passenger, src.thread, src.departure_time, src.station_order, src.distance
        from carriages_booking rcb
        inner join lateral (
            select s.id as schedule_id, s.thread, s.departure_time, s.arrival_time, rs.*
            from schedule s inner join routes_details rs on s.route_details = rs.id
            where s.thread = (select s2.thread from schedule s2 where s2.id = rcb.departure_point)
            ) as src on ((src.schedule_id between rcb.departure_point and rcb.arrival_point) and departure_time is not null)
        order by rcb.id, station_order
    loop
        day := DATE(i_trip.departure_time);
        index := array_position(day_list, day);
        pass_append := 0;
        thread_append := 0;

        if index is null then
            day_list := array_append(day_list, day);
            uniq_list := array_append(uniq_list, row(array[i_trip.pass_id], array[i_trip.thread_id])::uniq_arr);
            sum_by_days := array_append(sum_by_days, (1, 1, i_trip.distance, day)::aggregation_report);
        else
            if array_position((uniq_list[index]::uniq_arr).passenger_arr, i_trip.pass_id) is null then
                uniq_list[index] := row(array_append((uniq_list[index]::uniq_arr).passenger_arr, i_trip.pass_id), (uniq_list[index]::uniq_arr).thread_arr)::uniq_arr;
                pass_append := 1;
            end if;
            if array_position((uniq_list[index]::uniq_arr).thread_arr, i_trip.thread_id) is null then
                uniq_list[index] := row((uniq_list[index]::uniq_arr).passenger_arr, array_append((uniq_list[index]::uniq_arr).thread_arr, i_trip.thread_id))::uniq_arr;
                thread_append := 1;
            end if;

            rep := sum_by_days[index];
            sum_by_days[index] := (rep.thread_count + thread_append, rep.pass_count + pass_append, rep.distance_sum + i_trip.distance, rep.calc_day)::aggregation_report;
        end if;
    end loop;

    foreach i_report in array
        (select array_agg(elem order by (elem::aggregation_report).calc_day) as sorted_array
         from unnest(sum_by_days) AS elem)
    loop
        if extract(quarter from prev_report.calc_day) != extract(quarter from i_report.calc_day) then
            final_report := array_append(final_report, row(tpd_day_sum.thread_count, tpd_day_sum.pass_count, tpd_day_sum.dist_sum,
                extract(quarter from prev_report.calc_day)::text || '-' || extract(year from prev_report.calc_day)::text)::accumulated_report
            );
            tpd_day_sum := (0, 0, 0, null);
        end if;

        if extract(year from prev_report.calc_day) != extract(year from i_report.calc_day) then
            final_report := array_append(final_report, row(tpd_quarter_sum.thread_count, tpd_day_sum.pass_count,
                tpd_day_sum.dist_sum, extract(year from i_report.calc_day))::accumulated_report
            );
            tpd_quarter_sum := (0, 0, 0, null);
        end if;

        tpd_day_sum.thread_count := tpd_day_sum.thread_count + i_report.thread_count;
        tpd_day_sum.pass_count := tpd_day_sum.pass_count + i_report.pass_count;
        tpd_day_sum.dist_sum := tpd_day_sum.dist_sum + i_report.distance_sum;

        tpd_quarter_sum.thread_count := tpd_quarter_sum.thread_count + i_report.thread_count;
        tpd_quarter_sum.pass_count := tpd_quarter_sum.pass_count + i_report.pass_count;
        tpd_quarter_sum.dist_sum := tpd_quarter_sum.dist_sum + i_report.distance_sum;

        tpd_year_sum.thread_count := tpd_year_sum.thread_count + i_report.thread_count;
        tpd_year_sum.pass_count := tpd_year_sum.pass_count + i_report.pass_count;
        tpd_year_sum.dist_sum := tpd_year_sum.dist_sum + i_report.distance_sum;

        final_report := array_append(final_report, row(tpd_day_sum.thread_count, tpd_day_sum.pass_count,
            tpd_day_sum.dist_sum, i_report.calc_day::text)::accumulated_report
        );

        prev_report := i_report;
    end loop;

    final_report := array_append(final_report, row(tpd_quarter_sum.thread_count, tpd_quarter_sum.pass_count, tpd_quarter_sum.dist_sum,
        extract(quarter from prev_report.calc_day)::text || '-' || extract(year from prev_report.calc_day)::text)::accumulated_report
    );
    final_report := array_append(final_report, row(tpd_year_sum.thread_count, tpd_year_sum.pass_count, tpd_year_sum.dist_sum,
        extract(year from i_report.calc_day))::accumulated_report
    );
    return final_report;
end;
$$ LANGUAGE plpgsql;

drop procedure if exists fix_schedule_by_delay(from_time timestamp, to_time timestamp);
create or replace procedure fix_schedule_by_delay(from_time timestamp, to_time timestamp) as $$
declare
    delay_cursor cursor for select * from delay;
    i_delay delay%rowtype;

    cur_schedule schedule%rowtype;
    i_schedule schedule%rowtype;
    s_list schedule[];
    cur_number int;
begin
    for i_delay in delay_cursor loop
        select s.* into cur_schedule from schedule s
        where s.id = i_delay.schedule_record;

        if cur_schedule.departure_time not between from_time and to_time then
            return;
        end if;

        select rs.station_order into cur_number from schedule s
            inner join routes_details rs on s.route_details = rs.id
        where s.id = i_delay.schedule_record;

        select array (
            select row(s.*) from schedule s
                inner join routes_details rs on s.route_details = rs.id
            where s.thread = cur_schedule.thread and
                  rs.station_order >= cur_number
            order by rs.station_order
        ) into s_list;

        foreach i_schedule in array s_list loop
            update schedule s set arrival_time = s.arrival_time + i_delay.arrival_delay,
                                  departure_time = s.departure_time + i_delay.arrival_delay + i_delay.departure_delay
            where s.id = i_schedule.id;
        end loop;

        update delay set arrival_delay = interval '0 second',
                         departure_delay = interval '0 second'
        where current of delay_cursor;
    end loop;
end;
$$ LANGUAGE plpgsql;