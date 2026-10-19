# Networking: companion material

Goes with the **Networking** course on Alfred Learning. The course works its incidents as readings of
command output; these let you produce that output yourself.

- [diagnosis-cheatsheet.md](diagnosis-cheatsheet.md): the commands, in the order the course works
  through a failure: name, route, port, application.
- [connectivity-runbook.md](connectivity-runbook.md): the capstone template, to fill in for a service
  you look after.

A quick tour of the three failures the course says mean different things:

```bash
nc -vz example.com 443        # succeeded: something is listening
nc -vz 127.0.0.1 9            # refused: the host answered, nothing listens on that port
nc -vz -w 3 10.255.255.1 443  # timed out: nothing answered at all, often a firewall dropping packets
```

Refused is fast and timed out is slow, and that difference alone tells you which layer to look at.
