# CI/CD Pipelines: companion material

Goes with the **CI/CD Pipelines** course on Alfred Learning. The course has you author workflow YAML
in the in-page terminal and checks its structure; here it runs on GitHub's machines.

| File | What it shows |
| --- | --- |
| [.github/workflows/ci.yml](.github/workflows/ci.yml) | Lint and test in parallel, build only after both pass, a smoke test of the image, a read-only token, actions pinned to commits |
| [.yamllint.yaml](.yamllint.yaml) | A yamllint configuration that understands workflow files |

## Check it on your machine first

The cheapest place to find a mistake is before you push:

```bash
actionlint .github/workflows/ci.yml
yamllint -c .yamllint.yaml .
```

## Run it on GitHub

GitHub runs workflows only from the root of a repository, so put this pipeline and the app from
[08-containers](../08-containers/) together in a new repository of your own:

```bash
mkdir ~/alfred-ci && cd ~/alfred-ci && git init -b main
cp -R /path/to/alfred-setup/materials/08-containers/app .
cp -R /path/to/alfred-setup/materials/10-cicd/.github /path/to/alfred-setup/materials/10-cicd/.yamllint.yaml .
git add -A && git commit -m "Add app and pipeline"
gh repo create alfred-ci --private --source . --push     # or create it on github.com and push
gh run watch                                              # follow the run from the terminal
```

## Things to try, from the course

- **A gate that gates.** Break the test (change the expected greeting in `app/server.test.js`) and
  push to a branch with a pull request. `test` fails and `image` never runs.
- **The YAML number trap.** Change `node-version: "24"` to `node-version: 24.10` and run yamllint and
  actionlint. Then think about what `3.10` without quotes would become.
- **Least privilege.** Delete the `permissions:` block and look at the token's permissions in the
  run's "Set up job" log. Put it back.
- **Why pin to a commit.** Look up what `actions/checkout@v7` points to today
  (`gh api repos/actions/checkout/git/ref/tags/v7.0.1`), and compare with the SHA in the workflow.
  A tag can be moved; a commit cannot.

The workflow is free to run in a public repository, and uses a few minutes of the free allowance in a
private one.
