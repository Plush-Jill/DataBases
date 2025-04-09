/* report */
select * from unnest(get_trip_report());

/* delay insert */
truncate table delay;
insert into delay (schedule_record, arrival_delay, departure_delay)
values (2, interval '10 minutes', interval '0 minutes');

call fix_schedule_by_delay('01-01-25'::timestamp, '01-08-25'::timestamp);

/* second trigger */
truncate table schedule cascade;
insert into schedule (route_structure_id, thread_id, arrival_time, departure_time)
values (1, 1, null, '01-01-2025 13:30:00'::timestamp);
insert into schedule (route_structure_id, thread_id, arrival_time, departure_time)
values (2, 1, '01-01-2025 13:20:00'::timestamp, '01-01-2025 13:30:00'::timestamp);

insert into schedule (route_structure_id, thread_id, arrival_time, departure_time)
values (2, 2, '01-01-2025 13:20:00'::timestamp, '01-01-2025 13:30:00'::timestamp);
insert into schedule (route_structure_id, thread_id, arrival_time, departure_time)
values (3, 2, '01-01-2025 16:30:00'::timestamp, '01-01-2025 16:40:00'::timestamp);

insert into schedule (route_structure_id, thread_id, arrival_time, departure_time)
values (1, 1, null, '01-01-2025 13:30:00'::timestamp);
insert into schedule (route_structure_id, thread_id, arrival_time, departure_time)
values (2, 1, '01-01-2025 13:20:00'::timestamp, '01-01-2025 13:30:00'::timestamp);
insert into schedule (route_structure_id, thread_id, arrival_time, departure_time)
values (3, 1, '01-01-2025 13:20:00'::timestamp, '01-01-2025 14:40:00'::timestamp);
select * from schedule order by thread_id, route_structure_id;

/* third trigger */
delete from routes r where r.id = 1;
delete from routes r where r.id = 2;
delete from routes r where r.id = 3;
select * from routes_structure;
select * from threads;
truncate table schedule cascade;
insert into schedule (id, route_structure_id, thread_id, arrival_time, departure_time)
values (null, 25, 4, null, '01-01-2025 13:30:00'::timestamp);
insert into schedule (id, route_structure_id, thread_id, arrival_time, departure_time)
values (null, 26, 4, '01-01-2025 13:20:00'::timestamp, '01-01-2025 13:30:00'::timestamp);
insert into schedule (id, route_structure_id, thread_id, arrival_time, departure_time)
values (null, 27, 4, '01-01-2025 13:20:00'::timestamp, '01-01-2025 13:30:00'::timestamp);

/* fourth trigger */
select count(*) from trains t
        inner join railroad_cars rc on t.id = rc.train_id
        inner join railroads_cars_booking rcb on rc.id = rcb.railroad_car_id
    where t.id = 1;
delete from trains t where t.id = 5;
select * from deleted_trains;