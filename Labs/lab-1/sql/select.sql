select count(*) from staff;
select count(*) from passengers;
select count(*) from trains;
select count(*) from railroad_cars;
select count(*) from routes;
select count(*) from railroads_cars_booking;
select count(*) from schedule;

select rcb.id, src.*
from railroads_cars_booking rcb
inner join lateral (
    select s.id as schedule_id, s.thread_id, s.departure_time, s.arrival_time, rs.*
    from schedule s inner join routes_structure rs on s.route_structure_id = rs.id
    where s.thread_id = (select s2.thread_id from schedule s2 where s2.id = rcb.departure_point)
    ) as src on ((src.schedule_id between rcb.departure_point and rcb.arrival_point) and departure_time is not null)
order by rcb.id, station_number_in_route;

with aggregate_by_day as (
    select count(distinct thread_id) as thread_count,
           count(distinct passenger_id) as passenger_count,
           sum(distance) as distance_sum,
           DATE(departure_time) as day
    from railroads_cars_booking rcb
             inner join lateral (
        select s.id as schedule_id, s.thread_id, s.departure_time, s.arrival_time, rs.*
        from schedule s inner join routes_structure rs on s.route_structure_id = rs.id
        where s.thread_id = (select s2.thread_id from schedule s2 where s2.id = rcb.departure_point)
        ) as src on ((src.schedule_id between rcb.departure_point and rcb.arrival_point) and departure_time is not null)
    group by DATE(departure_time)
), accumulate_day as (
    select sum(thread_count) over (partition by extract(year from day), extract(quarter from day) order by day) as thread_count,
           sum(passenger_count) over (partition by extract(year from day), extract(quarter from day) order by day) as passenger_count,
           sum(distance_sum) over (partition by extract(year from day), extract(quarter from day) order by day) as distance_sum,
           day as day,
           extract(quarter from day) as quarter,
           extract(year from day) as year,
           day::text as date_t
    from aggregate_by_day
), accumulate_quarter as (
    select
        distinct on (extract(quarter from day)) extract(quarter from day),
        sum(thread_count) over (partition by extract(year from day) order by extract(quarter from day)) as thread_count,
        sum(passenger_count) over (partition by extract(year from day) order by extract(quarter from day)) as passenger_count,
        sum(distance_sum) over (partition by extract(year from day) order by extract(quarter from day)) as distance_sum,
        day + interval '130 days' as day,
        extract(quarter from day) as quarter,
        extract(year from day) as year,
        extract(quarter from day)::text || '-' || extract(year from day)::text as date_t
    from aggregate_by_day
), accumulate_year as (
    select
        distinct on (extract(year from day)) extract(year from day),
        sum(thread_count) over (order by extract(year from day)) as thread_count,
        sum(passenger_count) over (order by extract(year from day)) as passenger_count,
        sum(distance_sum) over (order by extract(year from day)) as distance_sum,
        day + interval '2 year' as day,
        4 as quarter,
        extract(year from day) as year,
        extract(year from day)::text as date_t
    from aggregate_by_day
)
select thread_count, passenger_count, distance_sum, date_t, day, quarter, year from accumulate_day
    union all
select thread_count, passenger_count, distance_sum, date_t, day, quarter, year from accumulate_quarter as aq
    union all
select thread_count, passenger_count, distance_sum, date_t, day, quarter, year from accumulate_year ay
order by year, quarter, day;