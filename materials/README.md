# Companion material

Starter files for each course on the Alfred Learning roadmap, in roadmap order.

**These are companions to the in-app courses, not a replacement for them.** Each course is complete
in the browser: it teaches the idea, gives you exercises in the terminal built into the page, and
checks your work. The files here let you do the same thing on your own computer, with the real
tools, once the course has explained them. Every folder's README says which lessons it goes with.

| Folder | Course | What is in it |
| --- | --- | --- |
| [01-security-awareness](01-security-awareness/) | Security Awareness Training | A personal security checklist and an incident playbook template |
| [02-local-env](02-local-env/) | Local Environment Setup | A portable shell profile, a global gitignore, an SSH config, a rebuild runbook |
| [03-programming](03-programming/) | Programming Languages | The same small tool in Python and in Go, with tests |
| [04-os-concepts](04-os-concepts/) | Operating System Concepts | A systemd service and timer pair, a safe cleanup script, a triage runbook |
| [05-networking](05-networking/) | Networking | A diagnosis cheat sheet and a connectivity runbook template |
| [06-security](06-security/) | Security | A least-privilege IAM policy, a threat model template, scanning commands |
| [07-git](07-git/) | Version Control with Git | A script that builds a practice repository with a conflict waiting, and a pre-commit config |
| [08-containers](08-containers/) | Containers | A small web app with a hardened multi-stage Dockerfile and a compose file |
| [09-kubernetes](09-kubernetes/) | Kubernetes | A kind cluster config and manifests that run the Containers app |
| [10-cicd](10-cicd/) | CI/CD Pipelines | A GitHub Actions workflow that lints, tests and builds the Containers app |

Copy a folder somewhere of your own before changing it, so `git pull` on this kit stays clean:

```bash
cp -R materials/08-containers ~/practice/containers
```

Everything here is safe to run on a personal computer: nothing deletes files outside the folder you
point it at, nothing needs an account, and the cloud examples are files to read and lint, not things
that create resources.
