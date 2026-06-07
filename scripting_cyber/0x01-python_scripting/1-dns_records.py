#!/usr/bin/env python3

import dns.resolver


def query_dns_records(domain_name):

    record_types = ['A', 'AAAA', 'MX', 'NS', 'TXT', 'SOA']
    results = {}

    for record_type in record_types:
        try:
            answers = dns.resolver.resolve(domain_name, record_type)
            results[record_type] = answers
        except (dns.resolver.NoAnswer,
                dns.resolver.NXDOMAIN,
                dns.resolver.NoNameservers):
            # Record type doesn't exist or domain not found — skip it
            pass

    return results


if __name__ == "__main__":
    import sys

    if len(sys.argv) != 2:
        print("Usage: python3 1-dns_records.py <domain>")
        sys.exit(1)

    domain_name = sys.argv[1]
    results = query_dns_records(domain_name)

    for record_type, response_text in results.items():
        print(f"\n{record_type} Records:")
        print(response_text.response.to_text())

    print("\nResults dictionary:", results)
