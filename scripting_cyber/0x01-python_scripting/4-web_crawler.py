#!/usr/bin/env python3
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse


def crawl_website(start_url, max_depth=2, visited=None, depth=0):

    if visited is None:
        visited = set()

    if depth > max_depth or start_url in visited:
        return visited

    try:
        response = requests.get(start_url, timeout=5)
    except requests.exceptions.RequestException:
        return visited

    visited.add(start_url)
    print(f"Crawling: {start_url}")

    base_domain = urlparse(start_url).netloc
    soup = BeautifulSoup(response.text, 'html.parser')

    for link in soup.find_all('a', href=True):
        next_url = urljoin(start_url, link['href'])
        if urlparse(next_url).netloc == base_domain:
            crawl_website(next_url, max_depth, visited, depth + 1)

    return visited


if __name__ == "__main__":
    print(crawl_website("https://example.com", 1))