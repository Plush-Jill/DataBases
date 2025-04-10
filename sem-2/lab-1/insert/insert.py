from random import randint
from datetime import datetime, time, timedelta
import psycopg
import matplotlib.pyplot as plt
import networkx
import random

INTEGER_MAX = 2147483647

hostname = 'localhost'
database = 'DB-project'
username = 'postgres'
password = '3255'
port = 5432

employees_count = 1000
num_nodes = 80
num_edges = 110
seed = 123
graph = None
matrix = None
routes_set = None
num_routes = 0
all_stations_in_routes = []


def insert_employees(db_connect):
    positions = ["pos-1", "pos-2", "pos-3", "pos-4", "pos-5"]
    created_employees = {position: [] for position in positions}

    with db_connect.cursor() as cursor:
        cursor.execute("truncate table employees cascade")
        # cursor.execute("alter sequence employees_id_seq restart with 1")

        emp_id = 1

        # Добавляем по одному сотруднику на каждую позицию
        for position in positions:
            name = f"name{emp_id}"
            manager_id = None if position == "pos-1" else \
            random.choice(created_employees[positions[positions.index(position) - 1]])[0]
            created_employees[position].append((emp_id, name, position, manager_id))
            emp_id += 1

        # Заполняем остальных сотрудников
        k = 0
        while emp_id <= employees_count:
            position = random.choices(positions, weights=[1, 2, 3, 4, 5])[0]
            manager_id = None
            if position != "pos-1":
                higher_position = positions[positions.index(position) - 1]
                if created_employees[higher_position]:
                    manager_id = random.choice(created_employees[higher_position])[0]
                else:
                    continue  # Нельзя создать подчинённого без руководителя

            name = f"name{emp_id}"
            created_employees[position].append((emp_id, name, position, manager_id))
            emp_id += 1

        insert_script = """
            insert into employees (id, name, position, manager) 
            values (%s, %s, %s, %s)
        """

        # Вставка данных в базу
        for position in positions:
            if created_employees[position]:
                cursor.executemany(insert_script, created_employees[position])

        db_connect.commit()
def insert_passengers(db_connect):
    with db_connect.cursor() as cursor:
        cursor.execute("truncate table passengers cascade")
        cursor.execute("alter sequence passengers_id_seq restart with 1")

        name_number = 1
        passport_series = 1000
        passport_number = 100000
        passengers = []
        for i in range(1000):
            passport_data = int(str(passport_series) + str(passport_number))
            passengers.append(("name" + str(name_number),))
            name_number += 1
            passport_number += 1
            passport_series += 1

        insert_script = "insert into passengers (name) values (%s)"
        cursor.executemany(insert_script, passengers)
def create_graph():
    global graph
    graph = networkx.gnm_random_graph(num_nodes, num_edges, seed)

    random.seed(seed)
    for edge_begin, edge_end in graph.edges():
        graph[edge_begin][edge_end]['weight'] = random.randint(100, 1000)

    adj_matrix = networkx.to_numpy_array(graph)
    matrix_length = adj_matrix.shape
    for i in range(matrix_length[0]):
        for j in range(matrix_length[0]):
            if (adj_matrix[i][j] == 0):
                adj_matrix[i][j] = -1
            if (i == j):
                adj_matrix[i][j] = 0

    global matrix
    matrix = adj_matrix
def read_route_details():
    with open('allRoutes.txt', 'r') as file:
        for line in file:
            stations_in_route = list(map(int, line.strip().split()))
            all_stations_in_routes.append(stations_in_route)
def insert_stations(db_connect):
    with db_connect.cursor() as cursor:
        cursor.execute("truncate table stations cascade")
        cursor.execute("alter sequence stations_id_seq restart with 1")

        name_number = 0
        stations_insert = []
        for i in range(num_nodes):
            stations_insert.append((i + 1, "station" + str(name_number)))
            name_number += 1

        insert_script = "insert into stations (id, name) values (%s, %s)"
        cursor.executemany(insert_script, stations_insert)
def insert_routes(db_connect):
    with db_connect.cursor() as cursor:
        cursor.execute("truncate table routes cascade")
        cursor.execute("alter sequence routes_id_seq restart with 1")

        route_number = 0
        routes_insert = []

        global num_routes
        for route in all_stations_in_routes[:5]:
            num_routes += 1
            route_number += 1
            routes_insert.append((route_number, "route" + str(route_number), route[0] + 1, route[route.__len__() - 1] + 1))

        insert_script = "insert into routes (number, name, departure_station, destination_station) values (%s, %s, %s, %s)"
        cursor.executemany(insert_script, routes_insert)
def insert_trains(db_connect):
    with db_connect.cursor() as cursor:
        cursor.execute("truncate table trains cascade")
        cursor.execute("alter sequence trains_id_seq restart with 1")

        cursor.execute("truncate table trips cascade")
        cursor.execute("alter sequence trips_id_seq restart with 1")

        cursor.execute("truncate table carriages cascade")
        cursor.execute("alter sequence carriages_id_seq restart with 1")

        category = ['category-1', 'category-2', 'category-3']
        category_index = 0

        trains = []
        for i in range(num_routes):
            trains.append((category[category_index], randint(1, num_nodes)))
            category_index += 1
            category_index %= 3

        insert_script = "insert into trains (category, head_station) values (%s, %s)"
        cursor.executemany(insert_script, trains)

        trips = []
        id = 1
        month_number = 1
        day_number = 1
        trip_date = datetime(2025, month_number, day_number, 12, 0, 0)
        for i in range(num_routes):
            trips.append((id, id, trip_date))
            id += 1
            month_number %= 3
            month_number += 1
            day_number %= 3
            day_number += 1


        insert_script = "insert into trips(train, route, trip_date) values (%s, %s, %s)"
        cursor.executemany(insert_script, trips)

        railroad_cars = []
        id = 1
        category_index = 0
        for i in range(num_routes):
            for j in range(1):
                railroad_cars.append((i + 1, j, category_index + 1))
                category_index += 1
                category_index %= 2

        insert_script = "insert into carriages(train, order_in_train, category) values (%s, %s, %s)"
        cursor.executemany(insert_script, railroad_cars)
def insert_routes_details(db_connect):
    with db_connect.cursor() as cursor:
        cursor.execute("truncate table routes_details cascade")
        cursor.execute("alter sequence routes_details_id_seq restart with 1")

        cursor.execute("select * from routes")
        routes = cursor.fetchall()

        details = []
        for routeId, name, departure, arrival in routes:
            station_number = 0
            distance = 0
            station_in_route = all_stations_in_routes[routeId - 1]
            for i, station in enumerate(station_in_route):
                details.append((routeId, station + 1, station_number, distance))
                distance = random.randint(200, 1000)
                station_number += 1

        insert_script = "insert into routes_details (route, station, station_order, distance) values (%s, %s, %s, %s)"
        cursor.executemany(insert_script, details)
def insert_schedule(db_connect):
    with db_connect.cursor() as cursor:
        cursor.execute("truncate table schedule_time cascade")
        cursor.execute("alter sequence schedule_time_id_seq restart with 1")

        schedule = []
        cursor.execute("select * from trips")
        trips_list = cursor.fetchall()
        month_number = 1
        day_number = 1
        for trip in trips_list:
            cursor.execute("select rs.* from trips t inner join routes_details rs on t.route = rs.route where t.id = %s order by station_order", (trip[0],))
            rs_list = cursor.fetchall()

            departure_time = None
            arrival_time = datetime(2025, month_number, day_number, 12, 0, 0)
            for structId, routeId, station, number, distance in rs_list:
                if (number == rs_list.__len__() - 1):
                    arrival_time = None
                schedule.append((structId, trip[0], arrival_time, departure_time))
                if (number != rs_list.__len__() - 1):
                    departure_time = arrival_time + timedelta(hours=1)
                    arrival_time = departure_time + timedelta(minutes=10)

            month_number %= 12
            month_number += 1
            day_number %= 28
            day_number += 1

        insert_script = "insert into schedule_time (station, trip, arrival_time, departure_time) values (%s, %s, %s, %s)"
        cursor.executemany(insert_script, schedule)
def insert_booking(db_connect):
    with db_connect.cursor() as cursor:
        cursor.execute("truncate table booking cascade")
        cursor.execute("alter sequence booking_id_seq restart with 1")

        booking = []

        passenger = 1
        id_index = 1
        select_script = "select s.* from schedule_time s inner join routes_details rs on s.id = rs.id where rs.route = %s order by station_order"
        cursor.execute("select * from trips")
        trip_list = cursor.fetchall()
        for trip in trip_list:
            cursor.execute(select_script, (trip[0],))
            trip_schedule = cursor.fetchall()
            cursor.execute("select cars.* from carriages cars inner join trains t on cars.train = t.id inner join trips t2 on t.id = t2.train where t2.id = %s", (trip[0],))
            trip_carriages = cursor.fetchall()

            for carriage in trip_carriages:
                for place in range(250):
                    booking.append((carriage[0], place, trip_schedule[0][0], trip_schedule[-1][0], passenger))

                passenger %= 1000
                passenger += 1
                id_index += 1

        insert_script = "insert into booking(carriage, place, departure_station, destination_station, passenger) values (%s, %s, %s, %s, %s)"
        cursor.executemany(insert_script, booking)
def insert_delay(db_connect):
    with db_connect.cursor() as cursor:
        cursor.execute("truncate table delay cascade")
        cursor.execute("alter sequence delay_id_seq restart with 1")

def insert(db_connect):
    print("creating graph...")
    create_graph()
    print("reading routes...")
    read_route_details()

    print("inserting employees...")
    # insertEmployees(dbConnect)
    insert_employees(db_connect)
    print("inserting passengers...")
    insert_passengers(db_connect)
    print("inserting stations...")
    insert_stations(db_connect)
    print("inserting routes...")
    insert_routes(db_connect)
    print("inserting trains...")
    insert_trains(db_connect)
    print("inserting routes details...")
    # insert_routes_details(db_connect)
    print("inserting schedule...")
    # insert_schedule(db_connect)
    print("inserting booking...")
    # insert_booking(db_connect)
    # insertDelay(dbConnect)
    print("inserted")

# def main():
try:
    print("trying to connect")
    db_connect = psycopg.connect(
                host = hostname,
                dbname = database,
                user = username,
                password = password,
                port = port)
    print("connected to database")
    # exit()
    db_connect.autocommit = True

    with db_connect.cursor() as cursor:
        cursor.execute("set search_path to public")
    print("start inserting")
    insert(db_connect)

except Exception as error:
    print(error)
finally:
    if db_connect is not None:
        db_connect.close()

