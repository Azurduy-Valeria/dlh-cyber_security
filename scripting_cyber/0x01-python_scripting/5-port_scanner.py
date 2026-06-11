#!/usr/bin/env python3
import socket


def check_port(host, port):
    
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(1)
    try:
        result = sock.connect_ex((host, port))
        return result == 0
    except socket.error:
        return False
    finally:
        sock.close()


if __name__ == "__main__":
    print(check_port("scanme.nmap.org", 80))