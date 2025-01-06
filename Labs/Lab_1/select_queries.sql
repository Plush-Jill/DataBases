-- 1. Выбрать всех студентов, учащихся у преподавателей с фамилией на «А»
--      в последние 2 года от текущей даты.
SELECT DISTINCT students.student_id,
                students.surname,
                students.name,
                students.patronymic
FROM students
    JOIN group_memberships ON students.student_id = group_memberships.student_id
    JOIN schedule ON group_memberships.group_id = schedule.group_id
    JOIN teachers ON schedule.teacher_id = teachers.teacher_id
    JOIN semesters ON schedule.semester_id = semesters.semester_id
WHERE LEFT(teachers.surname, 1) = 'A'
AND semesters.start_date >= CURRENT_DATE - INTERVAL '2 years';

-- 2. Выбрать все группы и среднюю успеваемость в них.
SELECT groups.group_id,
       AVG(academic_performance.mark) AS average_mark -- вернёт null если вообще все оценки не выставлены, если у группы будут не все оценки, null поля игнорируются
FROM groups
         JOIN group_memberships ON groups.group_id = group_memberships.group_id
         LEFT JOIN academic_performance ON group_memberships.student_id = academic_performance.student_id
GROUP BY groups.group_id;

-- 3. Выбрать преподавателей, у которых студентов-отличников больше 10.
SELECT teachers.teacher_id,
       teachers.surname,
       teachers.name,
       teachers.patronymic
FROM teachers
    JOIN academic_performance ON teachers.teacher_id = academic_performance.teacher_id -- переделал на один join
WHERE academic_performance.mark = 5
GROUP BY teachers.teacher_id, teachers.surname, teachers.name, teachers.patronymic
HAVING COUNT(DISTINCT academic_performance.student_id) > 10;

-- 4. Найти группы, в которых был период без старосты в последний год.
SELECT groups.group_id
FROM groups
    LEFT JOIN group_heads ON groups.group_id = group_heads.group_id
    JOIN semesters ON group_heads.semester_id = semesters.semester_id
WHERE group_heads.student_id IS NULL AND semesters.start_date >= CURRENT_DATE - INTERVAL '1 year';

-- 5. Посчитать среднее количество студентов у каждого преподавателя за последние 3 года.
SELECT teachers.teacher_id,
       teachers.surname,
       teachers.name,
       teachers.patronymic,
       AVG(student_count) AS average_student_count
FROM (
    SELECT teachers.teacher_id,
           COUNT(DISTINCT students.student_id) AS student_count
    FROM teachers
        JOIN schedule ON teachers.teacher_id = schedule.teacher_id
        JOIN group_memberships ON schedule.group_id = group_memberships.group_id
        JOIN students ON group_memberships.student_id = students.student_id
        JOIN semesters ON schedule.semester_id = semesters.semester_id
    WHERE semesters.start_date >= CURRENT_DATE - INTERVAL '3 years'
    GROUP BY teachers.teacher_id, semesters.semester_id
    )
    AS teacher_student_counts
JOIN teachers ON teachers.teacher_id = teacher_student_counts.teacher_id
GROUP BY teachers.teacher_id, teachers.surname, teachers.name, teachers.patronymic;

-- 6. Выбрать ТОП-10 преподавателей с максимальной нагрузкой за последние 2 года
--      (нагрузка = сумма по дням (от сегодня до <сегодня и 2 года>)
--      / число преподаваемых академических часов).
SELECT teachers.teacher_id,
       teachers.surname,
       teachers.name,
       teachers.patronymic,
       (DATE_PART('day', semesters.end_date - semesters.start_date) + 1) / -- end_date - start_date
        (COUNT(schedule.lesson_number) * 2)
           AS workload
FROM teachers
    JOIN schedule ON teachers.teacher_id = schedule.teacher_id
    JOIN semesters ON schedule.semester_id = semesters.semester_id
WHERE semesters.start_date >= CURRENT_DATE - INTERVAL '2 year'
GROUP BY teachers.teacher_id, teachers.surname, teachers.name, teachers.patronymic
ORDER BY workload DESC
LIMIT 10;

-- 7. Выбрать преподавателей, ведущих за последний год предметы, не входящие в его специализацию,
--      отсортировать по убыванию числа таких расхождений.
SELECT teachers.teacher_id,
       teachers.surname,
       teachers.name,
       teachers.patronymic,
       COUNT(schedule.subject_id) AS mismatch_count
FROM teachers
    JOIN schedule ON teachers.teacher_id = schedule.teacher_id
    JOIN semesters ON schedule.semester_id = semesters.semester_id --убрал join со специализацией преподавателей
WHERE semesters.start_date >= CURRENT_DATE - INTERVAL '1 year'
    AND NOT EXISTS(
        SELECT 1
        FROM teacher_specializations
        WHERE teacher_specializations.teacher_id = teachers.teacher_id
            AND teacher_specializations.subject_id = schedule.subject_id
)
GROUP BY teachers.teacher_id, teachers.surname, teachers.name, teachers.patronymic
ORDER BY mismatch_count DESC;

-- 8. Выбрать группу с самой высокой успеваемостью.
SELECT groups.group_id,
       AVG(academic_performance.mark) AS average_mark
FROM groups
         JOIN group_memberships ON groups.group_id = group_memberships.group_id
         JOIN academic_performance ON group_memberships.student_id = academic_performance.student_id
GROUP BY groups.group_id
ORDER BY average_mark DESC
LIMIT 1;

-- либо явно вернуть все группы с максимальной успеваемостью, добавив
-- HAVING AVG(academic_performance.mark) = (
--     SELECT MAX(AVG(academic_performance.mark))
--     FROM groups
--              JOIN group_memberships ON groups.group_id = group_memberships.group_id
--              JOIN academic_performance ON group_memberships.student_id = academic_performance.student_id
--     GROUP BY groups.group_id
-- )

-- 9. Найти всех студентов, получивших 2 у одного преподавателя на одной сессии. Переделать. >=2 студентов 2 от одного и того же преподавателя.
SELECT students.student_id,
       students.surname,
       students.name,
       students.patronymic,
       academic_performance.subject_id,
       academic_performance.mark,
       teachers.surname,
       teachers.name,
       teachers.patronymic
FROM students
    JOIN academic_performance ON students.student_id = academic_performance.student_id
    JOIN teachers ON academic_performance.teacher_id = teachers.teacher_id
WHERE academic_performance.mark = 2
    AND EXISTS (
        SELECT 1
        FROM academic_performance inner_ap
        WHERE inner_ap.teacher_id = academic_performance.teacher_id
--         AND inner_ap.subject_id = academic_performance.subject_id
        AND inner_ap.mark = 2
        GROUP BY inner_ap.teacher_id
        HAVING COUNT(inner_ap.student_id) >= 2
    );




-- 9. Найти всех студентов, получивших 2 у одного преподавателя на одной сессии. Переделать. >=2 студентов 2 от одного и того же преподавателя.
select academic_performance.student_id
from academic_performance
where academic_performance.mark = 2
and academic_performance.teacher_id in (
    select teacher_id
    from academic_performance
    where mark = 2
    group by teacher_id
    having count(*) >= 2
);




