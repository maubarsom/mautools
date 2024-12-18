import json
import datetime as dt
import logging

import requests

def to_datadog_timestamp(x: dt.datetime) -> int:
    return int(x.timestamp()) * 1000

def from_datadog_timestamp(x: int) -> dt.datetime:
    return dt.datetime.fromtimestamp(x.timestamp()/1000)

def datadog_time_spent_to_seconds(x: int):
    return x/ 1e9

def format_rum_data(data: dict) -> dict:
    formatted_data =  data['attributes']['attributes'].copy()
    formatted_data["tags_"] = data['attributes']['tags']
    formatted_data["timestamp_"] = data['attributes']['timestamp']
    return formatted_data

class DatadogRUM:
    def __init__(self, api_key, app_key):
        self._DD_API_KEY = api_key
        self._DD_APP_KEY = app_key
        self._http_headers = {
            "Content-Type": "application/json",
            "DD-API-KEY": self._DD_API_KEY,
            "DD-APPLICATION-KEY": self._DD_APP_KEY,
        }
        self._url = "https://api.datadoghq.eu/api/v2/rum/events/search"
        
        self._page_limit = 100
        
        self._logger = logging.Logger(self.__class__)
        self._logger.addHandler(logging.StreamHandler())
        self._logger.setLevel(logging.DEBUG)
        
    def _query(self, *, url=None, data:dict = None) -> dict:
        self._logger.debug(f"_query({url=}, {data=})")
        url = url if url is not None else self._url
        
        if data:
            json_data = json.dumps(data)
            response = requests.post(url, headers=self._http_headers, data=json_data)
        else:
            response = requests.get(url, headers=self._http_headers)

        if response.status_code == 200:
            response_data = response.json()
        else:
            raise RuntimeError(f"Something went wrong with the query {response.status_code}: {response.text}")
         
        return response_data
    
    def _query_with_pagination(self, *, url=None, data:dict = None, max_results=100) -> dict:
        page_counter = 1
        result_items = []
        
        response = self._query(url=url, data=data)
        result_items.extend(response['data'])

        while "links" in response and len(result_items) < max_results:
            page_counter += 1
            self._logger.debug(f"Fetching page {page_counter} from query {data}")
            response = self._query(url=response['links']['next'])
            result_items.extend(response['data'])
            
        return result_items
        

    def list_user_sessions(self, start:dt.datetime, end:dt.datetime, max_results=100):
        base_query = {
            "filter": {
                "query":"@type:session @session.type:user",
                "from": to_datadog_timestamp(start),
                "to":to_datadog_timestamp(end),
            },
            "page": {
                "limit": self._page_limit
            },
            "sort": "-timestamp"
        }

        return self._query_with_pagination(data=base_query, max_results=max_results)
    
    def list_session_events(self, session_id:str, start:int, end:int, max_results=100) -> dict:
        base_query = {
            "filter": {
                "query": f"@session.id:{session_id}",
                "from": to_datadog_timestamp(start),
                "to":to_datadog_timestamp(end),
            },
            "page": {
                "limit": self._page_limit
            },
            "sort": "-timestamp"
        }
        return self._query_with_pagination(data=base_query, max_results=max_results)
