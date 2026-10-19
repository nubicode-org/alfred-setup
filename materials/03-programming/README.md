# Programming Languages: companion material

Goes with the **Programming Languages** course on Alfred Learning. In the course, the in-page terminal
cannot run Python or Go, so exercises are graded on the code you write. Here you can run it.

The same small tool, `hostcheck`, written twice, so you can compare the languages the way the course's
capstone does. Given host names, it checks that each resolves and that a TCP port answers, and exits
non-zero if any fails, which is what makes a tool usable from a pipeline.

## Python

```bash
cd python
python3 -m venv .venv && . .venv/bin/activate     # a project's own Python, as the course recommends
python3 hostcheck.py example.com localhost --port 443
python3 -m unittest -v
deactivate
```

Things the course points out, to find in [python/hostcheck.py](python/hostcheck.py):

- `argparse` gives you `--help`, defaults and errors for free.
- Exceptions are caught narrowly (`socket.gaierror`, `OSError`), never with a bare `except:`.
- The exit code is the result: 0 when every host answered, 1 otherwise.

## Go

```bash
cd go
go run . example.com localhost --port 443
go test ./...
go build -o hostcheck . && ./hostcheck --help      # one file you can copy to any machine
```

In [go/main.go](go/main.go): errors are values, returned and wrapped with `fmt.Errorf("...: %w", err)`
so the caller sees what failed and why, and `errors.Is` still works on the result.

## Which one?

Run both, then write the decision the capstone asks for: which would you choose for a tool your team
runs on CI runners, and which for one you hand to other teams' machines? What would make you change
your mind?
