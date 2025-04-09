

with raw_dayly_report as (
    select
        extract(year from departure_time)       as year,
        extract(quarter from departure_time)    as quarter,
        date(departure_time)                    as day,
        count(distinct trip)                    as trip_count,
        count(distinct booking.id)              as passenger_count,
        sum(distance)                           as distance_sum
    from booking
        inner join lateral (
            select
                schedule_time.id as schedule_id,
                schedule_time.trip,
                schedule_time.departure_time,
                schedule_time.arrival_time,
                routes_details.*
            from schedule_time
                inner join routes_details on schedule_time.station = routes_details.id where schedule_time.trip = (
                        select
                            schedule_time.trip
                        from schedule_time
                            where schedule_time.id = booking.departure_station
                            )
        ) as details on (
            (details.schedule_id between booking.departure_station and booking.arrival_station)
            and departure_time is not null)
    group by rollup (
        extract(year from departure_time),
        extract(quarter from departure_time),
        date(departure_time)
    )
),
aggregated_data as (
    select
                                                                                                                                            year,
                                                                                                                                            quarter,
                                                                                                                                            day,

        sum(passenger_count)                                                            over (partition by quarter, year order by day)      as day_passengers_count,
        sum(case when day is null then passenger_count else 0 end)                      over (partition by year order by quarter)           as quarter_passengers_count,
        sum(case when day is null AND quarter is null then passenger_count else 0 end)  over (order by year)                                as year_passengers_count,

        sum(trip_count)                                                                 over (partition by quarter, year order by day)                                                          as day_trips_count,
        sum(case when day is null then trip_count else 0 end)                           over (partition by year order by quarter)           as quarter_trips_count,
        sum(case when day is null AND quarter is null then trip_count else 0 end)       over (order by year)                                as year_trips_count,

        sum(distance_sum)                                                               over (partition by quarter, year order by day)      as day_distance,
        sum(case when day is null then distance_sum else 0 end)                         over (partition by year order by quarter)           as quarter_distance,
        sum(case when day is null AND quarter is null then distance_sum else 0 end)     over (order by year)                                as year_distance

    from raw_dayly_report
)
select
    (case when day is null and quarter is null then year::text
        else case when day is null and quarter is not null then year || '-Q' || quarter else day::text end end)                 as date,

    (case when day is null and quarter is null then year_trips_count
        else case when day is null and quarter is not null then quarter_trips_count else day_trips_count end end)               as trip_count,

    (case when day is null and quarter is null then year_passengers_count
        else case when day is null and quarter is not null then quarter_passengers_count else day_passengers_count end end)     as passenger_count,

    (case when day is null and quarter is null then year_distance
        else case when day is null and quarter is not null then quarter_distance else day_distance end end)                     as distance_sum
from aggregated_data;
