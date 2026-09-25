import unittest
from pathlib import Path
import sys

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(REPO_ROOT))

from tool.ci.resolve_ci_network import query_dns, test_tcp_443, WELL_KNOWN_GOOGLE_IPS


class ResolveCiNetworkTests(unittest.TestCase):
    def test_well_known_ips_non_empty(self):
        self.assertGreater(len(WELL_KNOWN_GOOGLE_IPS), 0)
        for ip in WELL_KNOWN_GOOGLE_IPS:
            self.assertFalse(ip.startswith("198.18."))
            parts = ip.split(".")
            self.assertEqual(len(parts), 4)

    def test_query_dns_unreachable_server_returns_empty(self):
        # A non-routable IP should timeout and return empty list cleanly
        result = query_dns("dl.google.com", dns_server="192.0.2.1")
        self.assertEqual(result, [])

    def test_tcp_443_unreachable_returns_false(self):
        result = test_tcp_443("192.0.2.1", timeout=0.1)
        self.assertFalse(result)


if __name__ == "__main__":
    unittest.main()
