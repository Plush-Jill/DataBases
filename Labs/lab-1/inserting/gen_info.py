import json
import requests

apiKey = "13a670e5-8fd1-4883-b1d3-670dc13f3851"

headers = {
    "Authorization": apiKey,
}

def getRoutesBetweenStations():
    url = "https://api.rasp.yandex.net/v3.0/search/"

    params = {
        "from": "s9610189",
        "to": "s2000002",
        "transport_types": "train",
        "limit": "1",
        "offset": "50"
    }
    response = requests.get(url, headers=headers, params=params)
    data = response.json()

    with open("getRoutesBetweenStations.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

    print("getRoutesBetweenStations")

def getStationSchedule():
    url = "https://api.rasp.yandex.net/v3.0/schedule/"

    params = {
        "station": "s9610189",
        "transport_types": "train",
        "offset": "200"
        # "limit": "1"
    }
    response = requests.get(url, headers=headers, params=params)
    data = response.json()

    with open("getStationSchedule.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

    print("getStationSchedule")

def followingStations():
    url = "https://api.rasp.yandex.net/v3.0/thread/"

    params = {
        "uid": "001YE_8_2",
        "date": "2025-04-30",
        "limit": "100"
    }

    response = requests.get(url, headers=headers, params=params)
    data = response.json()

    with open("followingStations.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

    print("followingStations")

def main():
    # getRoutesBetweenStations()
    # getStationSchedule()
    followingStations()

if __name__ == '__main__':
    main()