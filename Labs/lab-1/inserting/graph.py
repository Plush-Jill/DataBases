import matplotlib.pyplot as plt
import networkx as nx
import random

INTEGER_MAX = 2147483647

num_nodes = 80
num_edges = 100
seed = 123
graph = None
routesSet = None
num_routes = -1

def dijsktra(matrix, size, start):
    minDist = [INTEGER_MAX] * size
    minDist[start] = 0

    minPath = [0] * size
    used = [False] * size

    for i in range(size):
        nearest = -1
        for v in range(size):
            if ((not used[v]) and (nearest == -1 or minDist[nearest] > minDist[v])):
                nearest = v

        if (minDist[nearest] == INTEGER_MAX):
            continue
        used[nearest] = True

        for v in range(size):
            len = minDist[nearest] + matrix[nearest][v]
            if (minDist[v] > len):
                if (matrix[nearest][v] != -1):
                    minDist[v] = int(len)
                    minPath[v] = int(nearest)

    return minDist, minPath

def createGraph():
    # global graph
    G = nx.gnm_random_graph(num_nodes, num_edges, seed)

    random.seed(seed)
    for u, v in G.edges():
        G[u][v]['weight'] = random.randint(100, 1000)

    adj_matrix = nx.to_numpy_array(G)
    matrixLen = adj_matrix.shape
    for i in range(matrixLen[0]):
        for j in range(matrixLen[0]):
            if (adj_matrix[i][j] == 0):
                adj_matrix[i][j] = -1
            if (i == j):
                adj_matrix[i][j] = 0

    global routesSet
    routesSet = set()
    for i in range(num_nodes):
        routesList = list(range(i + 1, num_nodes))
        for j in range(i + 1, int(num_nodes)):
            randomIndex = random.randint(1, routesList.__len__()) - 1
            popIndex = routesList.pop(randomIndex)
            routesSet.add((i + 1, popIndex + 1))

    global num_routes
    num_routes = routesSet.__len__()

    print(num_routes)
    # print(adj_matrix)
    allStationsRoutes = []
    for route in routesSet:
        minDist, minPath = dijsktra(adj_matrix, num_nodes, route[0] - 1)
        v = route[1] - 1

        index = 0
        stationsRoute = []
        while (v != route[0] - 1 and index < num_nodes):
           v = minPath[v]
           stationsRoute.append(v)
           index += 1
        if (index != num_nodes and stationsRoute.__len__() >= 7):
            allStationsRoutes.append(stationsRoute)

    return allStationsRoutes

def main():
    allStationsRoutes = createGraph()
    print(allStationsRoutes.__len__())

    with open('allRoutes.txt', 'w') as file:
        for route in allStationsRoutes:
            for station in route:
                file.write(str(station) + " ")
            file.write("\n")

    # pos = nx.spring_layout(G)
    # plt.figure(figsize=(8, 6))
    # nx.draw(G, pos, with_labels=True, node_color="lightblue", edge_color="gray", node_size=800, font_size=10)
    # edge_labels = {(u, v): G[u][v]['weight'] for u, v in G.edges()}
    # nx.draw_networkx_edge_labels(G, pos, edge_labels=edge_labels, font_size=10, font_color="red")
    # plt.title(f"Случайный граф G({num_nodes}, {num_edges}) с весами рёбер")
    # plt.show()

if __name__ == "__main__":
    main()