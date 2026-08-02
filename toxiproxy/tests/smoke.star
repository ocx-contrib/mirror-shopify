# tests/smoke.star — stable across upstream releases AND across all three
# variants. This one script runs against every variant bundle the pipeline
# builds (a variant is a plan entry, not a matrix axis, so there is no
# per-variant `tests:` axis and none is needed):
#   default (full)  -> ships BOTH toxiproxy-cli + toxiproxy-server
#   client          -> ships toxiproxy-cli only
#   server          -> ships toxiproxy-server only
#
# The smoke API exposes no variant/identifier signal, so each probe has to be
# gated on whether the binary is present at all. The gate CANNOT read the
# bundle tree: `ocx.exists`/`read_file` admit only the scratch root, and
# `ocx.package_root` is rejected as "path escapes the sandbox" (measured — the
# obvious `ocx.exists(ocx.package_root + "/" + name)` reds every leg). Nor can
# we probe by running the binary: `ocx.run` aborts the whole script when
# argv[0] is missing. So gate on the platform's always-present locator
# (`command -v` via sh on unix, `where` on Windows), which resolves the
# composed PATH and returns presence as an exit code.
#
# Bazel dialect: no top-level `if`/`for` — branch inside a `def` and call it,
# or use an if-EXPRESSION.
WIN = ocx.target_platform.os == ocx.os.Windows
EXE = ".exe" if WIN else ""
CLI = "toxiproxy-cli" + EXE
SRV = "toxiproxy-server" + EXE

def on_path(name):
    if WIN:
        return ocx.run("where", name).exit_code == 0
    return ocx.run("sh", "-c", "command -v " + name).exit_code == 0

# Every variant bundle must put at least one toxiproxy binary on PATH. This is
# the floor that catches an empty or wrong-flavour bundle; the per-binary
# blocks below are what prove the one(s) present actually run.
expect.true(on_path(CLI) or on_path(SRV))

def check_cli():
    if not on_path(CLI):
        return
    # Tier 1 + 2: liveness + version SHAPE (never vendor string / exact
    # version — those churn every release and assert nothing about behaviour).
    r = ocx.run(CLI, "--version")
    expect.ok(r)
    expect.matches(r.stdout, r"\d+\.\d+\.\d+")
    # Tier 3: the subcommand surface exists — exit-code probe, not help prose.
    expect.eq(ocx.run(CLI, "help", "list").exit_code, 0)
    # Hermetic behaviour: with no server to talk to, `list` must FAIL rather
    # than exit 0. Proves the binary is a real client that attempts the HTTP
    # call, without needing a live server in the container.
    expect.ne(ocx.run(CLI, "list").exit_code, 0)

def check_server():
    if not on_path(SRV):
        return
    # Tier 1 + 2: liveness + version SHAPE.
    r = ocx.run(SRV, "--version")
    expect.ok(r)
    expect.matches(r.stdout, r"\d+\.\d+\.\d+")

check_cli()
check_server()
