import socket
import threading
import unittest

import hostcheck


class HostcheckTest(unittest.TestCase):
    def test_a_listening_port_passes(self):
        server = socket.socket()
        server.bind(("127.0.0.1", 0))
        server.listen()
        port = server.getsockname()[1]
        threading.Thread(target=server.accept, daemon=True).start()
        try:
            self.assertTrue(hostcheck.check("127.0.0.1", port, 2).ok)
        finally:
            server.close()

    def test_a_name_that_does_not_resolve_fails(self):
        result = hostcheck.check("no-such-host.invalid", 443, 2)
        self.assertFalse(result.ok)
        self.assertIn("does not resolve", result.detail)

    def test_exit_code_is_one_when_any_host_fails(self):
        self.assertEqual(hostcheck.main(["no-such-host.invalid", "--timeout", "1"]), 1)


if __name__ == "__main__":
    unittest.main()
