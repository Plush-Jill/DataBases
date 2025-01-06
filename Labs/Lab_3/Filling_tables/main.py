# from encodings.punycode import insertion_sort
from random import randint
from datetime import datetime, timedelta
from decimal import Decimal
import psycopg
import random

hostname = 'localhost'
database = 'lab_3'
username = 'postgres'
password = '3255'
port_id = 5432

stations_count = 1000
trains_count = 1000
passengers_count = 80_000
employees_count = 1000
cities_count = 50


def insert_stations(db_connect):
    with db_connect.cursor() as cursor:
        cursor.execute("truncate table stations cascade")
        cursor.execute("alter sequence stations_id_seq restart with 1")

        stations = []

        for station_number in range(1, stations_count + 1):
            stations.append(("station_" + str(station_number), "city_" + str(randint(1, cities_count))))


        insert_script = "insert into stations (name, city) values (%s, %s)"
        cursor.executemany(insert_script, stations)


def insert_trains(db_connect):
    with db_connect.cursor() as cursor:
        cursor.execute("truncate table trains cascade")
        cursor.execute("alter sequence trains_id_seq restart with 1")

        train_categories = ["category-1", "category-2"]
        train_number = 1
        destination_station = 1
        departure_station = stations_count
        head_station = 1
        trains = []


        for i in range(trains_count):
            trains.append((destination_station,
                           departure_station,
                           head_station,
                           random.choice(train_categories)))
            train_number += 1
            destination_station += 1
            departure_station -= 1
            head_station += 1



        insert_script = "insert into trains (destination_station, departure_station, head_station, category) values (%s, %s, %s, %s)"
        cursor.executemany(insert_script, trains)

def insert_passengers(db_connect):
    with db_connect.cursor() as cursor:
        cursor.execute("truncate table passengers cascade")
        cursor.execute("alter sequence passengers_id_seq restart with 1")

        names = ["Игорь", "Владимир", "Юрий", "Михаил", "Александр", "Дмитрий", "Егор", "Владислав", "Илья"]
        surnames = ["Мангараков", "Бокк", "Вегрен", "Бирюля", "Кардаш", "Лутцев", "Загнеев", "Давыдов", "Бочкарёв", "Перетятько",
                    "Новиков"]
        patronymics = ["Дмитриевич", "Валерьевич", "Сергеевич", "Витальевич", "Владимирович", "Дмитриевич", "Александрович",
                       "Игоревич"]


        passengers = []
        start_passport_number = 1_000_000_000
        current_passport_number = start_passport_number

        for i in range (passengers_count):
            passengers.append((random.choice(names),
                               random.choice(surnames),
                               random.choice(patronymics),
                               current_passport_number
                               ))
            current_passport_number += 1 + (i % randint(5000, 10000))

        insert_script = "insert into passengers (name, surname, patronymic, passport_data) values (%s, %s, %s, %s)"
        cursor.executemany(insert_script, passengers)


def insert_train_structs(db_connect):
    with db_connect.cursor() as cursor:
        cursor.execute("truncate table train_struct cascade")

        train_id = 1
        train_structs = []

        for i in range(trains_count):
            reserved_tickets_count = randint(500, 1000)
            coupe_tickets_count = randint(500, 1000)
            suite_tickets_count = randint(500, 1000)

            general_tickets_count = reserved_tickets_count + coupe_tickets_count + suite_tickets_count

            train_structs.append((train_id,
                                  general_tickets_count,
                                  reserved_tickets_count,
                                  coupe_tickets_count,
                                  suite_tickets_count
                                  ))

            train_id += 1

        insert_script = "insert into train_struct (train_number, general_tickets_count, reserved_tickets_count, coupe_tickets_count, suite_tickets_count) values (%s, %s, %s, %s, %s)"
        cursor.executemany(insert_script, train_structs)


def insert_routes(db_connect):
    with db_connect.cursor() as cursor:
        cursor.execute("TRUNCATE TABLE route_stations CASCADE")
        cursor.execute("TRUNCATE TABLE routes CASCADE")
        cursor.execute("ALTER SEQUENCE routes_id_seq RESTART WITH 1")

        routes = []
        route_stations = []

        for train_id in range(1, trains_count + 1):
            train_stations_count = randint(5, 10)
            current_route_stations_ids = random.sample(range(1, stations_count + 1), train_stations_count)

            departure_station = current_route_stations_ids[0]
            destination_station = current_route_stations_ids[-1]

            # Создаём маршрут
            cursor.execute(
                "insert into routes (departure_station, destination_station) values (%s, %s) RETURNING id",
                (departure_station, destination_station)
            )
            route_id = cursor.fetchone()[0]

            # Заполняем станции маршрута
            for station_order, station_id in enumerate(current_route_stations_ids, start=1):
                stop_duration_minutes = randint(10, 20)
                route_stations.append((route_id, station_id, station_order))

        # Вставляем данные в route_stations
        insert_script = """
        insert into route_stations (route_id, station_id, stop_order)
        values (%s, %s, %s)
        """
        cursor.executemany(insert_script, route_stations)

    db_connect.commit()


def insert_schedule(db_connect):
    with db_connect.cursor() as cursor:
        # Очистка таблиц расписаний
        cursor.execute("TRUNCATE TABLE schedule_time CASCADE")
        cursor.execute("TRUNCATE TABLE schedule_routes CASCADE")
        cursor.execute("ALTER SEQUENCE schedule_routes_id_seq RESTART WITH 1")

        # Получаем маршруты поездов
        cursor.execute("""
            SELECT r.id, r.departure_station, r.destination_station
            FROM routes r
            ORDER BY r.id
        """)
        routes = cursor.fetchall()  # [(route_id, departure_station, destination_station), ...]

        schedule_routes = []
        schedule_times = []

        # Генерация расписаний
        for train_id in range(1, trains_count + 1):
            for route_id, departure_station, destination_station in routes:
                # Вставка маршрута в расписание
                cursor.execute(
                    """
                    INSERT INTO schedule_routes (route_id, train_id)
                    VALUES (%s, %s) RETURNING id
                    """,
                    (route_id, train_id)
                )
                schedule_id = cursor.fetchone()[0]

                # Получаем станции маршрута
                cursor.execute("""
                    SELECT station_id, stop_order
                    FROM route_stations
                    WHERE route_id = %s
                    ORDER BY stop_order
                """, (route_id,))

                route_stations = cursor.fetchall()  # [(station_id, stop_order), ...]

                # Сохраняем предыдущее время отправления
                previous_departure = datetime.now()

                for index, (station_id, stop_order) in enumerate(route_stations):
                    # Время до следующей станции и случайная задержка
                    travel_time = timedelta(minutes=randint(30, 120))
                    delay_minutes = randint(0, 10)

                    if index == 0:
                        arrival_time = previous_departure
                        departure_time = arrival_time + timedelta(minutes=randint(5, 10))
                    else:
                        arrival_time = previous_departure + travel_time
                        departure_time = arrival_time + timedelta(minutes=randint(5, 15))

                    # Фактическое прибытие с задержкой
                    real_arrival_time = arrival_time + timedelta(minutes=delay_minutes)

                    # Добавляем запись в расписание времени
                    schedule_times.append((
                        schedule_id,
                        station_id,
                        arrival_time,
                        real_arrival_time,
                        departure_time - arrival_time  # Продолжительность остановки
                    ))

                    previous_departure = departure_time

        # Вставляем данные в schedule_time
        insert_script = """
        INSERT INTO schedule_time (
            schedule_id,
            station_id,
            planned_arrival_time,
            real_arrival_time,
            stop_duration
        ) VALUES (%s, %s, date_trunc('minute', %s), date_trunc('minute', %s), %s)
        """
        cursor.executemany(insert_script, schedule_times)

    db_connect.commit()


def insert_passengers_trips(db_connect):
    with db_connect.cursor() as cursor:
        cursor.execute("truncate table passengers_trips cascade")
        cursor.execute("alter sequence passengers_trips_id_seq restart with 1")

        cursor.execute("SELECT id FROM passengers")
        passengers_ids = [row[0] for row in cursor.fetchall()]

        cursor.execute("SELECT id, train_id FROM schedule")
        schedule_data = cursor.fetchall()  # [(schedule_id, train_id), ...]

        # Условные категории мест
        seat_categories = ['reserved', 'coupe', 'suite']

        trips = []

        # Случайное распределение поездок
        for passenger_id in random.sample(passengers_ids, k = len(passengers_ids)):  # Уникальные пассажиры
            schedule_id, train_id = random.choice(schedule_data)

            # Определение категории места для поездки
            seat_category = random.choice(seat_categories)

            # Добавление записи
            trips.append((passenger_id, schedule_id, seat_category))

        # Вставка данных в таблицу
        insert_script = """
        INSERT INTO passengers_trips (passenger_id, schedule_id, seat_category) 
        VALUES (%s, %s, %s)
        """
        cursor.executemany(insert_script, trips)
        db_connect.commit()


def insert_employees(db_connect):
    with db_connect.cursor() as cursor:
        cursor.execute("truncate table employees cascade")
        cursor.execute("alter sequence employees_id_seq restart with 1")

        # Данные для заполнения
        names = ["Игорь", "Владимир", "Юрий", "Михаил", "Александр", "Дмитрий", "Егор", "Владислав", "Илья"]
        surnames = ["Мангараков", "Бокк", "Вегрен", "Бирюля", "Кардаш", "Лутцев", "Загнеев", "Давыдов", "Бочкарёв", "Перетятько",
                    "Новиков"]
        patronymics = ["Дмитриевич", "Валерьевич", "Сергеевич", "Витальевич", "Владимирович", "Дмитриевич", "Александрович",
                       "Игоревич"]
        positions = ["pos-1", "pos-2", "pos-3", "pos-4", "pos-5"]  # Перечисленные позиции

        cursor.execute("""
                    select t.id as train_id, s.city as head_station_city 
                    from trains t
                    join stations s on t.head_station = s.id
                """)
        train_data = cursor.fetchall()  # [(train_id, head_station_city), ...]

        cursor.execute("select distinct city from stations")
        available_cities = [row[0] for row in cursor.fetchall()]  # Список уникальных городов

        employees = []
        created_employees = {position: [] for position in positions}  # Группируем сотрудников по должности

        emp_id = 1
        while emp_id <= employees_count:  # Генерация 50 сотрудников
            name = random.choice(names)
            surname = random.choice(surnames)
            patronymic = random.choice(patronymics)
            position = random.choice(positions)
            city = random.choice(available_cities)

            # Выбираем поезд для бригады, если город совпадает с головной станцией
            local_trains = [train_id for train_id, head_station_city in train_data if head_station_city == city]
            if not local_trains:  # Если нет поездов, формируемых в этом городе, пропускаем
                continue
            brigade = random.choice(local_trains)

            # Назначение начальника (для всех кроме pos-1)
            supervisor_id = None
            if position != "pos-1":
                higher_position_index = positions.index(position) - 1
                higher_position = positions[higher_position_index]
                possible_supervisors = [emp for emp in created_employees[higher_position] if emp[1] == city]
                if not possible_supervisors:  # Если нет подходящих начальников, пропускаем
                    continue
                supervisor_id = random.choice(possible_supervisors)[0]

            # Добавляем сотрудника в список
            employees.append((emp_id, name, surname, patronymic, position, supervisor_id, city, brigade))
            created_employees[position].append((emp_id, city))  # Обновляем список созданных сотрудников

            emp_id += 1  # Переходим к следующему сотруднику

        # Вставка данных
        insert_script = """
                insert into employees (id, name, surname, patronymic, position, supervisor_id, city, brigade) 
                values (%s, %s, %s, %s, %s, %s, %s, %s)
                """
        cursor.executemany(insert_script, employees)
        db_connect.commit()


def insert(db_connect):
    print("inserting...")
    print("insert_stations()...")
    insert_stations(db_connect)

    print("insert_trains()...")
    insert_trains(db_connect)

    print("insert_passengers()...")
    insert_passengers(db_connect)

    print("insert_train_structs()...")
    insert_train_structs(db_connect)

    print("insert_routes()...")
    insert_routes(db_connect)
    #
    # print("insert_schedule()...")
    # insert_schedule(db_connect)
    #
    # print("insert_passengers_trips()...")
    # insert_passengers_trips(db_connect)

    print("insert_employees()...")
    insert_employees(db_connect)

    print("inserted")



def update(dbConnect):
    print("update")


def main():
    db_connect = None
    try:
        db_connect = psycopg.connect(
            host = hostname,
            dbname = database,
            user = username,
            password = password,
            port = port_id)

        db_connect.autocommit = True
        print("connected to database")
        # return
        with db_connect.cursor() as cursor:
            cursor.execute("set search_path to public")

        insert(db_connect)
        # update(db_connect)

    except Exception as error:
        print(error)
    finally:
        if db_connect is not None:
            db_connect.close()


if __name__ == '__main__':
    main()