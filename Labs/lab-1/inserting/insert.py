from random import randint
from datetime import datetime, time, timedelta
import psycopg
import matplotlib.pyplot as plt
import networkx as nx
import random

INTEGER_MAX = 2147483647

hostname = 'localhost'
database = 'sem-2'
username = 'postgres'
password = '3255'
port = 5432

def insertEmployees(dbConnect):
    with dbConnect.cursor() as cursor:
        cursor.execute("truncate table employees cascade")
        cursor.execute("alter sequence employees_id_seq restart with 1")

        position = ['pos-1', 'pos-2', 'pos-3']
        name_number = 0
        passport_number = 0
        passport_series = 0
        employees = []
        for i in range(2):
            employees.append(("name" + str(name_number), int(str(passport_series) + str(passport_number)), position[0], None))
            name_number += 1
            passport_number += 1
            passport_series += 1

        manager_id = 1
        for i in range(10):
            employees.append(("name" + str(name_number), int(str(passport_series) + str(passport_number)), position[1], manager_id))
            name_number += 1
            manager_id += 1
            passport_number += 1
            passport_series += 1
            if (manager_id > 2):
                manager_id = 1

        manager_id = 3
        for i in range(20):
            employees.append(("name" + str(name_number), int(str(passport_series) + str(passport_number)), position[1], manager_id))
            name_number += 1
            manager_id += 1
            passport_number += 1
            passport_series += 1
            if (manager_id > 3 + 10):
                manager_id = 3

        manager_id = 13
        for i in range(80):
            employees.append(("name" + str(name_number), int(str(passport_series) + str(passport_number)), position[2], manager_id))
            name_number += 1
            manager_id += 1
            passport_number += 1
            passport_series += 1
            if (manager_id > 13 + 20):
                manager_id = 13
        insert_script = "insert into employees (name, passport_data, position, manager) values (%s, %s, %s, %s)"
        cursor.executemany(insert_script, employees)

def insertPassengers(dbConnect):
    with dbConnect.cursor() as cursor:
        cursor.execute("truncate table passengers cascade")
        cursor.execute("alter sequence passengers_id_seq restart with 1")

        name_number = 5221
        passport_number = 0
        passport_series = 0
        passengers = []
        for i in range(1000):
            passengers.append(("name" + str(name_number), int(str(passport_series) + str(passport_number))))
            name_number += 1
            passport_number += 1
            passport_series += 1

        insert_script = "insert into passengers (name, passport_data) values (%s, %s)"
        cursor.executemany(insert_script, passengers)

num_nodes = 80
num_edges = 110
seed = 123
graph = None
matrix = None
routesSet = None
num_routes = 0

def createGraph():
    global graph
    graph = nx.gnm_random_graph(num_nodes, num_edges, seed)

    random.seed(seed)
    for edge_begin, edge_end in graph.edges():
        graph[edge_begin][edge_end]['weight'] = random.randint(100, 1000)

    adj_matrix = nx.to_numpy_array(graph)
    matrix_length = adj_matrix.shape
    for i in range(matrix_length[0]):
        for j in range(matrix_length[0]):
            if (adj_matrix[i][j] == 0):
                adj_matrix[i][j] = -1
            if (i == j):
                adj_matrix[i][j] = 0

    global matrix
    matrix = adj_matrix

allStationsInRoutes = []
def readRouteDetails():
    with open('allRoutes.txt', 'r') as file:
        for line in file:
            staionsInRoute = list(map(int, line.strip().split()))
            allStationsInRoutes.append(staionsInRoute)

def insertStations(dbConnect):
    with dbConnect.cursor() as cursor:
        cursor.execute("truncate table stations cascade")
        cursor.execute("alter sequence stations_id_seq restart with 1")

        nameNumber = 0
        stationsInsert = []
        for i in range(num_nodes):
            stationsInsert.append((i + 1, "station" + str(nameNumber)))
            nameNumber += 1

        insertScript = "insert into stations (id, name) values (%s, %s)"
        cursor.executemany(insertScript, stationsInsert)

def insertRoutes(dbConnect):
    with dbConnect.cursor() as cursor:
        cursor.execute("truncate table routes cascade")
        cursor.execute("alter sequence routes_id_seq restart with 1")

        nameNumber = 0
        routesInsert = []

        global num_routes
        for route in allStationsInRoutes[:5]:
            num_routes += 1
            nameNumber += 1
            routesInsert.append(("route" + str(nameNumber), route[0] + 1, route[route.__len__() - 1] + 1))

        insertScript = "insert into routes (name, departure_point, arrival_point) values (%s, %s, %s)"
        cursor.executemany(insertScript, routesInsert)

def insertTrains(dbConnect):
    with dbConnect.cursor() as cursor:
        cursor.execute("truncate table trains cascade")
        cursor.execute("alter sequence trains_id_seq restart with 1")

        cursor.execute("truncate table threads cascade")
        cursor.execute("alter sequence threads_id_seq restart with 1")

        cursor.execute("truncate table carriages cascade")
        cursor.execute("alter sequence carriages_id_seq restart with 1")

        category = ['category-1', 'category-2', 'category-3']
        categoryIndex = 0

        trains = []
        for i in range(num_routes):
            trains.append((category[categoryIndex], randint(1, num_nodes)))
            categoryIndex += 1
            categoryIndex %= 3

        insertScript = "insert into trains (category, head_station) values (%s, %s)"
        cursor.executemany(insertScript, trains)

        threads = []
        id = 1
        monthNumber = 1
        dayNumber = 1
        tripDate = datetime(2025, monthNumber, dayNumber, 12, 0, 0)
        for i in range(num_routes):
            threads.append((id, id, tripDate))
            id += 1
            monthNumber %= 3
            monthNumber += 1
            dayNumber %= 3
            dayNumber += 1


        insertScript = "insert into threads(train, route, trip_date) values (%s, %s, %s)"
        cursor.executemany(insertScript, threads)

        railroadCars = []
        id = 1
        categoryIndex = 0
        for i in range(num_routes):
            for j in range(1):
                railroadCars.append((i + 1, j, categoryIndex + 1))
                categoryIndex += 1
                categoryIndex %= 2

        insertScript = "insert into carriages(train, order_in_train, category) values (%s, %s, %s)"
        cursor.executemany(insertScript, railroadCars)

def insertRoutesDetails(dbConnect):
    with dbConnect.cursor() as cursor:
        cursor.execute("truncate table routes_details cascade")
        cursor.execute("alter sequence routes_details_id_seq restart with 1")

        cursor.execute("select * from routes")
        routes = cursor.fetchall()

        structure = []
        for routeId, name, departure, arrival in routes:
            stationNumber = 0
            distance = 0
            stationInRoute = allStationsInRoutes[routeId - 1]
            for i, station in enumerate(stationInRoute):
                structure.append((routeId, station + 1, stationNumber, distance))
                distance = random.randint(200, 1000)
                stationNumber += 1

        insertScript = "insert into routes_details (route, station, station_order, distance) values (%s, %s, %s, %s)"
        cursor.executemany(insertScript, structure)

def insertSchedule(dbConnect):
    with dbConnect.cursor() as cursor:
        cursor.execute("truncate table schedule cascade")
        cursor.execute("alter sequence schedule_id_seq restart with 1")

        schedule = []
        cursor.execute("select * from threads")
        threadsList = cursor.fetchall()
        monthNumber = 1
        dayNumber = 1
        for thread in threadsList:
            cursor.execute("select rs.* from threads t inner join routes_details rs on t.route = rs.route where t.id = %s order by station_order", (thread[0],))
            rsList = cursor.fetchall()

            departureTime = None
            arrivalTime = datetime(2025, monthNumber, dayNumber, 12, 0, 0)
            for structId, routeId, station, number, distance in rsList:
                if (number == rsList.__len__() - 1):
                    arrivalTime = None
                schedule.append((structId, thread[0], arrivalTime, departureTime))
                if (number != rsList.__len__() - 1):
                    departureTime = arrivalTime + timedelta(hours=1)
                    arrivalTime = departureTime + timedelta(minutes=10)

            monthNumber %= 12
            monthNumber += 1
            dayNumber %= 28
            dayNumber += 1

        insertScript = "insert into schedule (routes_details, thread, departure_time, arrival_time) values (%s, %s, %s, %s)"
        cursor.executemany(insertScript, schedule)

def insertRailroadBooking(dbConnect):
    with dbConnect.cursor() as cursor:
        cursor.execute("truncate table carriages_booking cascade")
        cursor.execute("alter sequence carriages_booking_id_seq restart with 1")

        booking = []
        railroadCarBook = []

        passanger = 1
        idIndex = 1
        selectScript = "select s.* from schedule s inner join routes_details rs on s.id = rs.id where rs.route = %s order by station_order"
        cursor.execute("select * from threads")
        threadList = cursor.fetchall()
        for thread in threadList:
            cursor.execute(selectScript, (thread[0],))
            threadSchedule = cursor.fetchall()
            cursor.execute("select cars.* from carriages cars inner join trains t on cars.train = t.id inner join threads t2 on t.id = t2.train where t2.id = %s", (thread[0],))
            threadRailcars = cursor.fetchall()

            for railroad in threadRailcars:
                for place in range(250):
                    railroadCarBook.append((railroad[0], place, threadSchedule[0][0], threadSchedule[-1][0], passanger))

                passanger %= 1000
                passanger += 1
                idIndex += 1

        insertScript = "insert into carriages_booking(carriage, place, departure_point, arrival_point, passenger) values (%s, %s, %s, %s, %s)"
        cursor.executemany(insertScript, railroadCarBook)

def insertDelay(dbConnect):
    with dbConnect.cursor() as cursor:
        cursor.execute("truncate table delay cascade")
        cursor.execute("alter sequence delay_id_seq restart with 1")

def insert(dbConnect):
    print("creating graph...")
    createGraph()
    print("reading routes...")
    readRouteDetails()

    print("inserting employees...")
    insertEmployees(dbConnect)
    print("inserting passengers...")
    insertPassengers(dbConnect)
    print("inserting stations...")
    insertStations(dbConnect)
    print("inserting routes...")
    insertRoutes(dbConnect)
    print("inserting trains...")
    insertTrains(dbConnect)
    print("inserting routes details...")
    insertRoutesDetails(dbConnect)
    print("inserting schedule...")
    insertSchedule(dbConnect)
    print("inserting booking...")
    insertRailroadBooking(dbConnect)
    # insertDelay(dbConnect)
    print("inserted")

# def main():
try:
    print("trying to connect")
    dbConnect = psycopg.connect(
                host = hostname,
                dbname = database,
                user = username,
                password = password,
                port = port)
    print("connected to database")
    # exit()
    dbConnect.autocommit = True

    with dbConnect.cursor() as cursor:
        cursor.execute("set search_path to public")
    print("start inserting")
    insert(dbConnect)

except Exception as error:
    print(error)
finally:
    if dbConnect is not None:
        dbConnect.close()

# if __name__ == '__main__':
#     main()
