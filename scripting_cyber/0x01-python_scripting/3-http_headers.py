#!/usr/bin/env python3
import requests

def get_http_headers(url):
        response = requests.get(url)
        return {
            'status_code': response.status_code,
            'headers': dict(response.headers)
        }
    except requests.exceptions.RequestException:
        return None


if __name__ == "__main__":
    print(get_http_headers("https://www.google.com"))