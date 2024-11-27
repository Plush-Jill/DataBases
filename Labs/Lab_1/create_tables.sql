CREATE TABLE students(
    student_id INT PRIMARY KEY,
    surname VARCHAR(50) NOT NULL,
    name VARCHAR(50) NOT NULL,
    patronymic VARCHAR(50)
);

CREATE TABLE semesters (
    semester_id INT PRIMARY KEY,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL
);

CREATE TABLE subjects(
    subject_id INT PRIMARY KEY,
    subject_name VARCHAR(50) NOT NULL
);

CREATE TABLE teachers(
    teacher_id INT PRIMARY KEY,
    surname VARCHAR(50) NOT NULL,
    name VARCHAR(50) NOT NULL,
    patronymic VARCHAR(50)
);

CREATE TABLE teacher_specializations (
    teacher_id INT NOT NULL REFERENCES teachers(teacher_id),
    subject_id INT NOT NULL REFERENCES subjects(subject_id),
    PRIMARY KEY (teacher_id, subject_id)
);

CREATE TABLE academic_performance(
    student_id INT NOT NULL REFERENCES students(student_id),
    subject_id INT NOT NULL REFERENCES subjects(subject_id),
    semester_id INT NOT NULL REFERENCES semesters(semester_id),
    teacher_id INT NOT NULL REFERENCES teachers(teacher_id),
    mark INT CHECK ( mark between 2 and 5),
    PRIMARY KEY (student_id, subject_id, semester_id)
);

CREATE TABLE groups(
    group_id INT PRIMARY KEY,
    study_start_year INT NOT NULL,
    study_end_year INT NOT NULL,
    faculty VARCHAR(50) NOT NULL
);

CREATE TABLE group_heads (
    group_id INT NOT NULL,
    semester_id INT NOT NULL,
    student_id INT,
    PRIMARY KEY (group_id, semester_id),
    FOREIGN KEY (group_id) REFERENCES groups(group_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (semester_id) REFERENCES semesters(semester_id)
);

CREATE TABLE group_memberships (
    student_id INT REFERENCES students(student_id),
    semester_id INT REFERENCES semesters(semester_id),
    group_id INT REFERENCES groups(group_id),
    PRIMARY KEY (student_id, semester_id)
);

CREATE TABLE subject_teacher_assignments (
    subject_id INT NOT NULL REFERENCES subjects(subject_id),
    teacher_id INT NOT NULL REFERENCES teachers(teacher_id),
    semester_id INT NOT NULL REFERENCES semesters(semester_id),
    lecture BOOLEAN NOT NULL DEFAULT FALSE,
    seminar BOOLEAN NOT NULL DEFAULT FALSE,
    lab BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (subject_id, teacher_id, semester_id)
);

-- CREATE TABLE group_subject_assignments (
--     group_id INT,
--     subject_id INT,
--     semester_id INT,
--     FOREIGN KEY (group_id) REFERENCES groups(group_id),
--     FOREIGN KEY (subject_id) REFERENCES subjects(subject_id),
--     FOREIGN KEY (semester_id) REFERENCES semesters(semester_id),
--     UNIQUE (group_id, subject_id, semester_id),
--     PRIMARY KEY (group_id, subject_id, semester_id)
-- );

CREATE TABLE lessons (
    lesson_number INT PRIMARY KEY,
    lesson_start_time TIME NOT NULL,
    lesson_end_time TIME NOT NULL,
    CHECK (lesson_start_time < lesson_end_time)
);


CREATE TYPE LessonType AS ENUM ('lecture', 'practice', 'lab');

CREATE TABLE schedule (
    semester_id INT,
    day_of_week INT CHECK (day_of_week BETWEEN 1 AND 7),
    group_id INT,
    subject_id INT,
    lesson_type LessonType,
    room_number INT NOT NULL,
    teacher_id INT,
    lesson_number INT REFERENCES lessons(lesson_number),
    FOREIGN KEY (group_id) REFERENCES groups(group_id),
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id),
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id),
    FOREIGN KEY (semester_id) REFERENCES semesters(semester_id),
    UNIQUE (group_id, subject_id, teacher_id, day_of_week, lesson_number, semester_id),
    UNIQUE (day_of_week, room_number, lesson_number, semester_id),
    PRIMARY KEY (day_of_week, group_id, subject_id, room_number, semester_id)
);