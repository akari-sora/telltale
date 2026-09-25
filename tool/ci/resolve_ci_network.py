#!/usr/bin/env python3
"""Resolves and binds real public IPs for CI dependencies (e.g. dl.google.com)
bypassing host-side Fake-IP (198.18.0.0/15) leakage into Docker containers.
"""
from __future__ import annotations

import socket
import struct
import subprocess
import sys
import time
import urllib.request


def query_dns(domain: str, dns_server: str = "8.8.8.8") -> list[str]:
    """Performs a direct UDP DNS query to a trusted public recursive resolver."""
    tx_id = 0x1234
    flags = 0x0100  # standard query, RD=1
    header = struct.pack("!HHHHHH", tx_id, flags, 1, 0, 0, 0)
    qname = b"".join(bytes([len(p)]) + p.encode() for p in domain.split(".")) + b"\x00"
    packet = header + qname + struct.pack("!HH", 1, 1)  # A, IN

    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(2.0)
    try:
        s.sendto(packet, (dns_server, 53))
        data, _ = s.recvfrom(512)
    except Exception:
        return []
    finally:
        s.close()

    offset = 12 + len(qname) + 4
    ips = []
    if len(data) < 12:
        return []
    ancount = struct.unpack("!H", data[6:8])[0]
    while offset < len(data) and len(ips) < ancount:
        if (data[offset] & 0xc0) == 0xc0:
            offset += 2
        else:
            while offset < len(data) and data[offset] != 0:
                offset += 1 + data[offset]
            offset += 1
        if offset + 10 > len(data):
            break
        atype, aclass, ttl, rdlength = struct.unpack("!HHIH", data[offset:offset+10])
        offset += 10
        if atype == 1 and rdlength == 4 and offset + 4 <= len(data):
            ips.append(socket.inet_ntoa(data[offset:offset+4]))
        offset += rdlength
    return ips


# Well-known Google Maven anycast / edge IPv4 addresses
WELL_KNOWN_GOOGLE_IPS = [
    "173.194.174.93",
    "173.194.174.91",
    "173.194.174.136",
    "173.194.174.190",
    "142.250.180.206",
    "142.250.72.206",
    "108.177.125.91",
    "108.177.125.190",
    "172.217.16.206",
]


def test_tcp_443(ip: str, timeout: float = 2.0) -> bool:
    try:
        s = socket.create_connection((ip, 443), timeout=timeout)
        s.close()
        return True
    except Exception:
        return False


def main() -> int:
    print("=== [RESOLVE-CI-NETWORK] Checking dl.google.com resolution ===")
    current_ips = []
    try:
        for a in socket.getaddrinfo("dl.google.com", 443):
            if a[0] == socket.AF_INET:
                current_ips.append(a[4][0])
    except Exception as e:
        print(f"System DNS failed: {e}")

    print(f"System DNS returned: {current_ips}")
    is_fake_ip = any(ip.startswith("198.18.") for ip in current_ips)

    working_ip = None

    if is_fake_ip or not current_ips:
        print("Detected Fake-IP (198.18.x.x) or empty resolution. Resolving via public DNS...")
        candidate_ips = []
        for dns_ip in ("8.8.8.8", "1.1.1.1", "223.5.5.5", "9.9.9.9"):
            resolved = query_dns("dl.google.com", dns_server=dns_ip)
            for r in resolved:
                if not r.startswith("198.18.") and r not in candidate_ips:
                    candidate_ips.append(r)
            if candidate_ips:
                print(f"Resolved via {dns_ip}: {candidate_ips}")
                break

        for ip in candidate_ips + WELL_KNOWN_GOOGLE_IPS:
            if test_tcp_443(ip):
                working_ip = ip
                print(f"Found working direct IP for dl.google.com: {ip}")
                break
    else:
        for ip in current_ips:
            if not ip.startswith("198.18.") and test_tcp_443(ip):
                working_ip = ip
                print(f"Current IP {ip} works.")
                break

    if not working_ip:
        print("Direct connection to Google IPs failed. Testing proxy on Docker gateway...")
        gateway = "172.17.0.1"
        try:
            route_out = subprocess.check_output(["ip", "route"], text=True, stderr=subprocess.DEVNULL)
            for line in route_out.splitlines():
                if "default via" in line:
                    gateway = line.split()[2]
                    break
        except Exception:
            pass

        for port in (7890, 7897, 10808, 10809, 8888, 8080):
            try:
                s = socket.create_connection((gateway, port), timeout=1.0)
                s.close()
                proxy_url = f"http://{gateway}:{port}"
                print(f"Found active proxy at {proxy_url}")
                with open("/tmp/ci-proxy-env.sh", "w") as f:
                    f.write(f"export http_proxy={proxy_url}\n")
                    f.write(f"export https_proxy={proxy_url}\n")
                    f.write(f"export HTTP_PROXY={proxy_url}\n")
                    f.write(f"export HTTPS_PROXY={proxy_url}\n")
                from pathlib import Path
                for prop_path in [
                    Path("/root/.gradle/gradle.properties"),
                    Path("/home/ubuntu/.gradle/gradle.properties"),
                    Path("/home/flutter/.gradle/gradle.properties"),
                    Path("android/gradle.properties"),
                ]:
                    if prop_path.parent.is_dir():
                        try:
                            with open(prop_path, "a") as pf:
                                pf.write(f"\nsystemProp.http.proxyHost={gateway}\nsystemProp.http.proxyPort={port}\n"
                                         f"systemProp.https.proxyHost={gateway}\nsystemProp.https.proxyPort={port}\n")
                        except Exception:
                            pass
                return 0
            except Exception:
                pass
        print("WARNING: Neither direct Google IP nor gateway proxy succeeded.")
    else:
        hosts_entry = f"\n{working_ip} dl.google.com maven.google.com dl-ssl.google.com\n"
        try:
            with open("/etc/hosts", "a") as f:
                f.write(hosts_entry)
            print(f"Updated /etc/hosts with: {hosts_entry.strip()}")
        except Exception as e:
            print(f"Note: Could not append to /etc/hosts (likely non-root or read-only): {e}")

    try:
        test_url = "https://dl.google.com/dl/android/maven2/com/android/application/com.android.application.gradle.plugin/9.1.0/com.android.application.gradle.plugin-9.1.0.pom"
        req = urllib.request.Request(test_url, headers={"User-Agent": "curl/7.88.1"})
        with urllib.request.urlopen(req, timeout=10) as resp:
            print(f"Verification: dl.google.com POM retrieved HTTP {resp.status} (bytes={len(resp.read())})")
    except Exception as e:
        print(f"Verification fetch error: {e}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
