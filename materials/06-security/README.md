# Security: companion material

Goes with the **Security** course on Alfred Learning, the defensive engineering half (the human half
is Security Awareness). Everything here is defensive: reading, scanning and limiting your own work.

| File | Course module | What it shows |
| --- | --- | --- |
| [iam-policy-least-privilege.json](iam-policy-least-privilege.json) | Identity and access | One job's AWS permissions: one bucket, one prefix, read and write, nothing else |
| [threat-model.md](threat-model.md) | The capstone | A threat model template for one service |

The IAM policy is a file to read and compare with the course's exercise, not something to apply. If
you have an AWS account and the CLI (`--with-cloud`), you can ask AWS to check it without creating
anything:

```bash
aws accessanalyzer validate-policy --policy-type IDENTITY_POLICY \
  --policy-document file://iam-policy-least-privilege.json
```

## Scanning your own work

```bash
# Secrets in a repository's whole history, not just the current files.
gitleaks git --redact -v /path/to/your/repo

# Known vulnerabilities in an image you built (try the one from 08-containers).
trivy image --severity HIGH,CRITICAL alfred-hello:dev

# Misconfiguration in Dockerfiles and Kubernetes manifests.
trivy config ../08-containers ../09-kubernetes
```

The course's point about scanners applies: a clean scan means "no known problem was found", not
"secure". Read what a finding says before fixing or dismissing it.
