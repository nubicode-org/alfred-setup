# Operating System Concepts: companion material

Goes with the **Operating System Concepts** course on Alfred Learning. The course's exercises author
these kinds of files in the in-page terminal; here they are complete, for a Linux machine (or Ubuntu
in WSL with systemd on). macOS has no systemd; read them there, and run the script.

| File | What it shows |
| --- | --- |
| [systemd/disk-report.service](systemd/disk-report.service) | A oneshot unit that runs as an unprivileged user, with a hardened sandbox |
| [systemd/disk-report.timer](systemd/disk-report.timer) | The timer that runs it daily, catching up if the machine was off |
| [cleanup-old-logs.sh](cleanup-old-logs.sh) | A cleanup script that defaults to a dry run and refuses dangerous paths |
| [triage-runbook.md](triage-runbook.md) | The capstone: the order to check a sick machine in |

Try the script first, which only prints what it would delete:

```bash
./cleanup-old-logs.sh /tmp 7
```

Install the unit pair as a **user** service (no root needed, and easy to remove):

```bash
mkdir -p ~/.config/systemd/user
cp systemd/disk-report.* ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user start disk-report.service        # run it once now
journalctl --user -u disk-report.service -n 20    # read what it printed
systemctl --user enable --now disk-report.timer
systemctl --user list-timers                      # when it runs next
```

Remove it again with `systemctl --user disable --now disk-report.timer` and deleting the two files.
For a user unit, drop the `User=` line; it is there to show what a system unit would use.
