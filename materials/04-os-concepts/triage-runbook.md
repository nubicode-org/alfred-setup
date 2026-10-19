# Triage runbook: a machine that is "slow" or "broken"

The course's capstone. Work top to bottom: each step rules out a whole category quickly, so you do not
spend an hour on the application when the disk was full. Write down what each command showed.

## 1. Is it up, and since when?

```bash
uptime                       # load averages: 1, 5 and 15 minutes. Compare with the CPU count (nproc).
journalctl -b -p warning -n 50 --no-pager    # warnings since this boot
```

## 2. Disk: full, or out of inodes?

```bash
df -h                        # space
df -i                        # inodes: "full" with free space means millions of small files
du -xh --max-depth=1 /var | sort -rh | head
```

If `df` says full and `du` cannot find it, a process is holding a deleted file open:
`sudo lsof +L1`. Restarting that process frees the space.

## 3. Memory: is it swapping, or was something killed?

```bash
free -h                      # "available" is the number that matters, not "free"
journalctl -k | grep -i -E 'out of memory|oom'    # the kernel's OOM killer leaves a note
```

## 4. CPU: who is using it?

```bash
top -o %CPU                  # or htop. Press 1 for per-CPU.
ps -eo pid,user,%cpu,%mem,stat,cmd --sort=-%cpu | head
```

A process in state `D` is waiting on disk or network, not using CPU. Many of them point back to step 2
or to storage.

## 5. The service itself

```bash
systemctl status <service>
journalctl -u <service> --since "1 hour ago" --no-pager
systemctl list-units --failed
```

## 6. Write down what you found

| Step | What I saw | Normal? |
| --- | --- | --- |
| Load | | |
| Disk | | |
| Memory | | |
| CPU | | |
| Service | | |

Conclusion, and what would have caught this earlier:
