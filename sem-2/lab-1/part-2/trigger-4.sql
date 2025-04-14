-- 4.	Написать триггер, который логирует
-- (записывает все параметры в отдельную таблицу учёта) все удаления поездов,
-- на которых было продано более 300 билетов. В таблицу аудита надо бы записать и число удалённых билетов.



create or replace function log_train() returns trigger as $$
declare
    deleted_train trains%rowtype;
    total_booking_count int;
begin
    deleted_train := old;
    select count(*) into total_booking_count
    from (
        select
            trains.id
        from trains
        where trains.id = deleted_train.id
    ) as booking_count

    inner join carriages on booking_count = carriages.train
    inner join booking on carriages.id = booking.carriage;

    if total_booking_count > 300 then
        insert into deleted_trains select *, total_booking_count from deleted_train;
    end if;
    return deleted_train;
end;
$$ language plpgsql;


create or replace trigger trains_delete_trigger
    after delete on trains
    for each row execute function log_train();