import requests
import json
from dotenv import load_dotenv
import os
from datetime import datetime, timedelta

load_dotenv()

URL_API = "https://app.ticketmaster.com/discovery/v2/events.json"
BATCH_SIZE = 20
MAX_RECORDS = 9e3
PER_DATE_LIMIT = 1000

def request_api_ticketmaster(params: dict, page=0, results=[]):
    params['page'] = page
    res = requests.get(URL_API, params=params)
    current_date = params['startDateTime']
    data = res.json()
    pk = None

    if '_embedded' in data and 'events' in data['_embedded']:
        events = data['_embedded']['events']
        for event in events:
            venue = event.get('_embedded', {}).get('venues', [{}])[0]
            pk = event.get('id')

            event_info = {
                "event_information": {
                    "id_event": pk,
                    "date_event_pull": current_date,
                    "name": event.get('name'),
                    "type": event.get('classifications', [{}])[0].get('segment', {}).get('name'),
                    "dates": event.get('dates', {}).get('start', {}).get('localDate'),
                    "status": event.get('dates', {}).get('status', {}).get('code'),
                    "genre": event.get('classifications', [{}])[0].get('genre', {}).get('name'),
                    "subgenre": event.get('classifications', [{}])[0].get('subGenre', {}).get('name')
                },
                "venue_details": {},
                "ticket_sales": {},
                "artist_performer_details": []
            }

            if venue:
                event_info["venue_details"] = {
                    "id_event": pk,
                    "date_event_pull": current_date,
                    "name": venue.get('name'),
                    "location": {
                        "latitude": venue.get('location', {}).get('latitude'),
                        "longitude": venue.get('location', {}).get('longitude'),
                        "address": venue.get('address', {}).get('line1')
                    },
                    "capacity": venue.get('capacity'),
                    "event_schedule": venue.get('upcomingEvents', {}).get('ticketmaster')
                }

            if 'priceRanges' in event:
                price_ranges = event.get('priceRanges', [{}])[0]
                event_info["ticket_sales"] = {
                    "id_event": pk,
                    "date_event_pull": current_date,
                    "price_range": {
                        "min": price_ranges.get('min'),
                        "max": price_ranges.get('max'),
                        "currency": price_ranges.get('currency')
                    },
                    "sale_dates": event.get('sales', {}).get('public', {}).get('startDateTime'),
                    "available_quantities": event.get('ticketLimit', {}).get('info')
                }

            performers = event.get('_embedded', {}).get('attractions', [])
            for performer in performers:
                performer_info = {
                    "id_event": pk,
                    "date_event_pull": current_date,
                    "name": performer.get('name'),
                    "genre": performer.get('classifications', [{}])[0].get('genre', {}).get('name'),
                    "popularity": performer.get('upcomingEvents', {}).get('ticketmaster'),
                    "event_participation_history": performer.get('upcomingEvents', {}).get('ticketmaster')
                }
                event_info["artist_performer_details"].append(performer_info)

            results.append(event_info)

            if len(results) >= MAX_RECORDS:
                return results

    if page < data.get('page', {}).get('totalPages', 0) - 1 and len(results) % PER_DATE_LIMIT != 0:
        return request_api_ticketmaster(params, page + 1, results)

    return results

def main():
    api_key = os.getenv('API_KEY')
    params = {
        'apikey': api_key,
        'countryCode': 'US',
        'size': BATCH_SIZE
    }
    results = []
    current_date = datetime.now()

    while len(results) < MAX_RECORDS:
        params['startDateTime'] = current_date.strftime("%Y-%m-%dT00:00:00Z")
        print(f"Requesting data for date: {params['startDateTime']}")  # Log debug

        results = request_api_ticketmaster(params, page=0, results=results)

        current_date -= timedelta(days=1)

    with open('ticketmaster.json', 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=4)

if __name__ == "__main__":
    main()
