# Connectivity runbook: ___ (service name)

The course's capstone. Fill it in for one service you look after, while it is working, so you know
what "normal" looks like when it is not.

## What normal looks like

| Check | Command | Expected |
| --- | --- | --- |
| Name | `dig +short ___` | |
| Port | `nc -vz ___ ___` | succeeded |
| TLS | `openssl s_client ... \| openssl x509 -noout -dates` | expires after ___ |
| Health | `curl -s -o /dev/null -w '%{http_code}' https://___/health` | 200 |
| Timing | `curl -s -o /dev/null -w '%{time_total}' https://___/` | under ___ s |

## Who and what is in the path

Client > ___ (DNS) > ___ (load balancer or proxy) > ___ (service) > ___ (database or dependency)

## When it fails

1. **Name**: does it resolve, here and from a public resolver? If only here is wrong, check
   `/etc/hosts` and the local cache.
2. **Port**: succeeded, refused or timed out? Refused: the service is down or bound to the wrong
   address. Timed out: a firewall or security group.
3. **TLS**: expired, or the wrong name?
4. **Application**: what status, and how long did the first byte take?

## Recent changes to check first

Anything changed in the last day is the first suspect: deploys, DNS records, firewall rules,
certificates.

| When | What changed | By whom |
| --- | --- | --- |
| | | |
