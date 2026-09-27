#!/usr/bin/env python3
"""Generate normal and burst traffic for the APIM security demonstration."""

import os
import sys
import time

import requests


target_url = os.getenv("TARGET_URL")
api_key = os.getenv("VALID_API_KEY")

if not target_url or not api_key:
    print("Set TARGET_URL and VALID_API_KEY before running the demo.", file=sys.stderr)
    sys.exit(2)

headers = {
    "Ocp-Apim-Subscription-Key": api_key,
    "Content-Type": "application/json",
}


def send_request(number: int) -> None:
    try:
        response = requests.get(target_url, headers=headers, timeout=10)
        print(f"Request {number:02d}: {response.status_code} {response.reason}")
    except requests.RequestException as error:
        print(f"Request {number:02d}: network error: {error}")


print("Scene 1: five normal requests")
for request_number in range(1, 6):
    send_request(request_number)
    time.sleep(0.4)

input("\nPress Enter to send the burst and trigger the gateway policy...")

print("\nScene 2: burst traffic")
for request_number in range(6, 16):
    send_request(request_number)