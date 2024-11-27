INSERT INTO students (student_id, surname, name, patronymic) VALUES
(1, 'Бочкарёв', 'Владислав', 'Александрович'),
(2, 'Давыдов', 'Егор', 'Дмитриевич'),
(3, 'Перетятько', 'Илья', 'Игоревич'),
(4, 'Бирюля', 'Михаил', 'Сергеевич'),
(5, 'Ахмедов', 'Владислав', 'Заурович'),
(6, 'Маслянко', 'Алексей', NULL),
(7, 'Суркова', 'Анастасия', NULL),
(8, 'Биточкин', 'Егор', NULL);


INSERT INTO semesters (semester_id, start_date, end_date) VALUES
(1, '2022-09-01', '2023-01-31'),
(2, '2023-02-01', '2023-06-30'),
(3, '2023-09-01', '2024-01-31'),
(4, '2024-02-01', '2024-06-30'),
(5, '2024-09-01', '2025-01-31'),
(6, '2025-02-01', '2025-06-30'),
(7, '2025-09-01', '2026-01-31'),
(8, '2026-02-01', '2026-06-30');


INSERT INTO subjects (subject_id, subject_name) VALUES
(1, 'Линал'),
(2, 'Матанализ'),
(3, 'Программирование на C'),
(4, 'ЭВМиПУ'),
(5, 'Психология'),
(6, 'ДУиТФКП'),
(7, 'Матлог'),
(8, 'Оси');


INSERT INTO teachers (teacher_id, surname, name, patronymic) VALUES
(1, 'Терсенов', 'Арис', 'Саввич'),
(2, 'Чуркин', 'Валерий', 'Авдеевич'),
(3, 'Петров', 'Евгений', 'Евгеньевич'),
(4, 'Киреев', 'Сергей', 'Евгеньевич'),
(5, 'Савостьянов', 'Александр', 'Николаевич'),
(6, 'Амандус', 'Наталья', 'Егоровна'),
(7, 'Пальчунов', 'Дмитрий', 'Евгеньевич'),
(8, 'Рутман', 'Михаил', 'Валерьевич');


INSERT INTO teacher_specializations (teacher_id, subject_id) VALUES
(1, 2),
(2, 1),
(3, 3),
(4, 4),
(5, 5),
(6, 6),
(7, 7),
(8, 8);


INSERT INTO academic_performance (student_id, subject_id, teacher_id, semester_id, mark) VALUES
(1, 1, 2, 1, 4),
(2, 1, 2, 1, 5),
(3, 2, 1, 1, 3),
(4, 3, 3, 1, 5),
(5, 4, 4, 1, 2),
(6, 5, 5, 1, 4),
(7, 6, 6, 1, 5),
(8, 7, 7, 1, 3);


INSERT INTO groups (group_id, study_start_year, study_end_year, faculty) VALUES
(1, 2022, 2026, 'ФИТ'),
(2, 2022, 2026, 'ФИТ');


INSERT INTO group_heads (group_id, student_id, semester_id) VALUES
(1, 1, 1),
(2, 5, 1),
(2, 5, 2);


INSERT INTO group_memberships (group_id, student_id, semester_id) VALUES
(1, 1, 1),
(1, 2, 1),
(1, 3, 1),
(1, 4, 1),
(2, 5, 1),
(2, 6, 1),
(2, 7, 1),
(2, 8, 1),
(1, 1, 2),
(1, 2, 2),
(1, 3, 2),
(1, 4, 2),
(2, 5, 2),
(2, 6, 2),
(2, 7, 2),
(2, 8, 2);


INSERT INTO subject_teacher_assignments (subject_id, teacher_id, semester_id, lecture, seminar, lab) VALUES
(1, 1, 1, TRUE, TRUE, FALSE),
(2, 2, 1, TRUE, TRUE, FALSE),
(3, 3, 1, TRUE, TRUE, TRUE),
(4, 4, 1, TRUE, FALSE, FALSE),
(5, 5, 1, TRUE, FALSE, FALSE),
(6, 6, 1, TRUE, TRUE, TRUE),
(7, 7, 1, TRUE, TRUE, TRUE),
(8, 8, 1, TRUE, FALSE, FALSE),

(1, 1, 2, TRUE, TRUE, FALSE),
(2, 2, 2, TRUE, TRUE, FALSE),
(3, 3, 2, TRUE, TRUE, TRUE),
(4, 4, 2, TRUE, FALSE, FALSE),
(5, 5, 2, TRUE, FALSE, FALSE),
(6, 6, 2, TRUE, TRUE, TRUE),
(7, 7, 2, TRUE, TRUE, TRUE),
(8, 8, 2, TRUE, FALSE, FALSE);


INSERT INTO group_subject_assignments (group_id, subject_id, semester_id) VALUES
(1, 1, 1),
(1, 2, 1),
(1, 3, 1),
(1, 4, 1),
(1, 5, 1),
(1, 6, 1),
(1, 7, 1),
(1, 8, 1),
(1, 1, 2),
(1, 2, 2),
(1, 3, 2),
(1, 4, 2),
(1, 5, 2),
(1, 6, 2),
(1, 7, 2),
(1, 8, 2),

(2, 1, 1),
(2, 2, 1),
(2, 3, 1),
(2, 4, 1),
(2, 5, 1),
(2, 6, 1),
(2, 7, 1),
(2, 8, 1),
(2, 1, 2),
(2, 2, 2),
(2, 3, 2),
(2, 4, 2),
(2, 5, 2),
(2, 6, 2),
(2, 7, 2),
(2, 8, 2);


INSERT INTO schedule (day_of_week, group_id, subject_id, teacher_id, room_number, lesson_start_time, lesson_end_time, semester_id) VALUES
(1, 1, 1, 1, 101, '09:00', '10:35', 1),
(1, 1, 2, 2, 102, '10:50', '12:25', 1),
(2, 1, 3, 3, 103, '12:40', '14:15', 1),
(2, 1, 4, 4, 104, '14:30', '16:05', 1),
(3, 1, 5, 5, 105, '09:00', '10:35', 1),
(3, 1, 6, 6, 106, '10:50', '12:25', 1),
(4, 1, 7, 7, 107, '12:40', '14:15', 1),
(5, 1, 8, 8, 108, '14:30', '16:05', 1),

(4, 1, 1, 1, 101, '09:00', '10:35', 1),
(4, 1, 2, 2, 102, '10:50', '12:25', 1),
(3, 1, 3, 3, 103, '12:40', '14:15', 1),
(3, 1, 4, 4, 104, '14:30', '16:05', 1),
(2, 1, 5, 5, 105, '09:00', '10:35', 1),
(2, 1, 6, 6, 106, '10:50', '12:25', 1),
(1, 1, 7, 7, 107, '12:40', '14:15', 1),
(1, 1, 8, 8, 108, '14:30', '16:05', 1);


