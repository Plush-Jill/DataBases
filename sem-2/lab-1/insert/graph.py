import matplotlib.pyplot as plt
import networkx as nx
import random

INTEGER_MAX = 2147483647

num_nodes = 80
num_edges = 100
seed = 123
graph = None
routes_set = None
num_routes = -1

def dijsktra(matrix, size, start):
    min_dist = [INTEGER_MAX] * size
    min_dist[start] = 0

    min_path = [0] * size
    used = [False] * size

    for i in range(size):
        nearest = -1
        for v in range(size):
            if ((not used[v]) and (nearest == -1 or min_dist[nearest] > min_dist[v])):
                nearest = v

        if (min_dist[nearest] == INTEGER_MAX):
            continue
        used[nearest] = True

        for v in range(size):
            len = min_dist[nearest] + matrix[nearest][v]
            if (min_dist[v] > len):
                if (matrix[nearest][v] != -1):
                    min_dist[v] = int(len)
                    min_path[v] = int(nearest)

    return min_dist, min_path

def create_graph():
    # global graph
    G = nx.gnm_random_graph(num_nodes, num_edges, seed)

    random.seed(seed)
    for u, v in G.edges():
        G[u][v]['weight'] = random.randint(100, 1000)

    adj_matrix = nx.to_numpy_array(G)
    matrix_length = adj_matrix.shape
    for i in range(matrix_length[0]):
        for j in range(matrix_length[0]):
            if (adj_matrix[i][j] == 0):
                adj_matrix[i][j] = -1
            if (i == j):
                adj_matrix[i][j] = 0

    global routes_set
    routes_set = set()
    for i in range(num_nodes):
        routes_list = list(range(i + 1, num_nodes))
        for j in range(i + 1, int(num_nodes)):
            randomIndex = random.randint(1, routes_list.__len__()) - 1
            popIndex = routes_list.pop(randomIndex)
            routes_set.add((i + 1, popIndex + 1))

    global num_routes
    num_routes = routes_set.__len__()

    print(num_routes)
    # print(adj_matrix)
    all_stations_routes = []
    for route in routes_set:
        min_dist, min_path = dijsktra(adj_matrix, num_nodes, route[0] - 1)
        v = route[1] - 1

        index = 0
        stations_route = []
        while (v != route[0] - 1 and index < num_nodes):
           v = min_path[v]
           stations_route.append(v)
           index += 1
        if (index != num_nodes and stations_route.__len__() >= 7):
            all_stations_routes.append(stations_route)

    return all_stations_routes



all_stations_routes = create_graph()
print(all_stations_routes.__len__())

with open('allRoutes.txt', 'w') as file:
    for route in all_stations_routes:
        for station in route:
            file.write(str(station) + " ")
        file.write("\n")
