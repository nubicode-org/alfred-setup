# Network diagnosis cheat sheet

Work outward. Each layer depends on the one before it, so the first one that fails is your problem.

## 1. The name

```bash
dig +short api.example.com             # what this machine's resolver returns
dig +short api.example.com @1.1.1.1    # what a public resolver returns; different means a local override or stale cache
dig api.example.com +trace             # the whole delegation, from the root down
grep api.example.com /etc/hosts        # an override that dig does not consult but most programs do
```

`dig` asks DNS directly. Most programs use the system resolver, which reads `/etc/hosts` first, so the
two can disagree. `getent hosts api.example.com` (Linux) or `dscacheutil -q host -a name api.example.com`
(macOS) shows what programs actually get.

## 2. The route

```bash
ip route get 93.184.216.34            # Linux: which interface and gateway this address would use
route -n get 93.184.216.34            # macOS
traceroute -n api.example.com         # each hop; * * * at the end usually means a firewall, not a dead link
```

## 3. The port

```bash
nc -vz api.example.com 443            # succeeded / refused / timed out
ss -ltnp                              # Linux: what is listening here, on which address, by which process
lsof -nP -iTCP -sTCP:LISTEN           # macOS equivalent
```

A service listening on `127.0.0.1` answers only this machine. On `0.0.0.0` (or `::`) it answers
everyone the firewall allows.

## 4. TLS

```bash
openssl s_client -connect api.example.com:443 -servername api.example.com </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates -ext subjectAltName
```

Check the name you used is in `subjectAltName`, and `notAfter` is in the future.

## 5. The application

```bash
curl -sv https://api.example.com/health -o /dev/null      # -v shows DNS, connect, TLS and HTTP in order
curl -s -o /dev/null -w 'dns %{time_namelookup}  connect %{time_connect}  tls %{time_appconnect}  first byte %{time_starttransfer}  total %{time_total}\n' https://api.example.com/
curl -sI https://api.example.com/ | head -n 1             # just the status
```

The `-w` timing line tells you which layer is slow: a high `dns` is the resolver, a high gap from
`tls` to `first byte` is the application.

## Reading HTTP errors

| Status | Usually means |
| --- | --- |
| 502 Bad Gateway | The proxy reached nothing behind it, or got garbage back |
| 503 Service Unavailable | The proxy knows the backend is down or overloaded |
| 504 Gateway Timeout | The backend took longer than the proxy was willing to wait |
