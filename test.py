import json

with open('ticketmaster.json') as f:
    data = json.load(f)

print(len(data))