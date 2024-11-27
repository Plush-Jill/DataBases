
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
SELECT computers.serial_number
FROM computers
    JOIN computer_components ON computers.serial_number = computer_components.computer_serial_number
WHERE computer_components.component_id IN (
    SELECT component_id
    FROM computer_components
    GROUP BY component_id
    HAVING COUNT(computer_serial_number) = 1
);


-- 2. Выбрать комплектующие, для которых нет замен.
SELECT components.component_id,
       components.name
FROM components
    LEFT JOIN computer_components ON components.component_id = computer_components.component_id
GROUP BY components.component_id
HAVING COUNT(DISTINCT computer_components.computer_serial_number) = 1;


-- 3. Выбрать самое дешевое комплектующее для каждой категории.
SELECT categories.category_id,
       components.component_id,
       components.name,
       MIN(components.price) AS min_price
FROM components
    JOIN categories ON components.category_id = categories.category_id
GROUP BY categories.category_id, components.component_id
ORDER BY categories.category_id;


-- 4. Вывести комплектующие,
--      которые находятся на первых 3 местах по уровню востребованности
--      (наиболее часто используемые во всех собранных компьютерах).
--      Примечание: если уровень востребованности
--      у двух комплектующих одинаковый, то обе находятся на одном месте.
SELECT components.component_id, components.name, COUNT(computer_components.computer_serial_number) AS usage_count
FROM computer_components
JOIN components ON computer_components.component_id = components.component_id
GROUP BY components.component_id
ORDER BY usage_count DESC
LIMIT 3;


-- 5. Вывести компьютеры с рентабельностью свыше 30%
--      (цена продажи на 30% больше стоимости производства).
SELECT computers.serial_number, SUM(computer_components.computer_sale_price) - SUM(components.price) AS profitability
FROM computers
JOIN computer_components ON computers.serial_number = computer_components.computer_serial_number
JOIN components ON computer_components.component_id = components.component_id
GROUP BY computers.serial_number
HAVING SUM(computer_components.computer_sale_price) > 1.3 * SUM(components.price);

