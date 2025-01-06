
-- Запросы:
-- 1. Выбрать компьютеры, в которых есть комплектующие,
--      использовавшиеся только на этом компьютере (нигде больше).
-- 2. Выбрать комплектующие, для которых нет замен.
-- 3. Выбрать самое дешевое комплектующее для каждой категории.
-- 4. Вывести комплектующие,
--      которые находятся на первых 3 местах по уровню востребованности
--      (наиболее часто используемые во всех собранных компьютерах).
--      Примечание: если уровень востребованности
--      у двух комплектующих одинаковый, то обе находятся на одном месте.
-- 5. Вывести компьютеры с рентабельностью свыше 30%
--      (цена продажи на 30% больше стоимости производства).



-- 1. Выбрать компьютеры, в которых есть комплектующие,
--      использовавшиеся только на этом компьютере (нигде больше).
select
    computer_components.computer_serial_number
from computer_components
where
    computer_components.component_id in (
        select
            component_id
        from computer_components
        group by component_id
        having count(computer_serial_number) = 1
    );


-- 2. Выбрать комплектующие, для которых нет замен.
select
    components.component_id,
    components.name
from components
where
    category_id in (
        select category_id
        from components
        group by components.category_id
        having count(component_id) = 1
    );


-- 3. Выбрать самое дешевое комплектующее для каждой категории.
select
    components.category_id,
    min(components.price) as min_price
from components
group by components.category_id
order by components.category_id;


-- 4. Вывести комплектующие,
--      которые находятся на первых 3 местах по уровню востребованности
--      (наиболее часто используемые во всех собранных компьютерах).
--      Примечание: если уровень востребованности
--      у двух комплектующих одинаковый, то обе находятся на одном месте.
select
    computer_components.component_id
from computer_components
group by computer_components.component_id
order by count(computer_components.computer_serial_number) desc
limit 3;


-- 5. Вывести компьютеры с рентабельностью свыше 30%
--      (цена продажи на 30% больше стоимости производства).
select
    computer_components.computer_serial_number
from computer_components
    join components ON computer_components.component_id = components.component_id
group by computer_components.computer_serial_number
having sum(computer_components.computer_sale_price) > 1.3 * sum(components.price);


select distinct
    component_id,
    max(components.price) over (partition by components.category_id) as max_price
from components
order by max_price desc