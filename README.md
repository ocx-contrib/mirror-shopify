# mirror-shopify

OCX mirrors for Shopify's open-source tools. One repository, one spec directory
per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [toxiproxy](https://github.com/Shopify/toxiproxy) | [`toxiproxy/mirror.yml`](toxiproxy/mirror.yml) | `ghcr.io/ocx-contrib/shopify/toxiproxy` | `ocx.sh/shopify/toxiproxy` | `MIT` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(variant, version, platform)` and only then pushed with cascade tags, after
which the result is announced into the OCX index.

> This repository previously published the same upstream to the flat coordinate
> `ocx.sh/toxiproxy`. `shopify/toxiproxy` is the grouped successor.

## Layout

```
mirror-base.yml         repo-wide policy every spec inherits via `extends:`
toxiproxy/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface, default variant (both binaries)
├── metadata-client.json  ─ client variant (toxiproxy-cli only)
├── metadata-server.json  ─ server variant (toxiproxy-server only)
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
└── tests/smoke.star    Starlark smoke test — one script, all three variants
```

`LICENSE` and `NOTICE.md` are shared at the root. Logos are **not** — each
package carries its own, because a repo-root `logo.*` sits in no workflow's
`paths:` filter, so replacing it would publish nothing until some unrelated
edit happened to fire.

⚠️ `extends:` is a **shallow** merge of top-level keys. A spec that restates
`platforms:` to change one runner drops every `containers:` entry with it, and
nothing reds — the legs simply stop existing, and every `os.features` claim
goes back to being asserted rather than verified. Restate a block in full or
not at all.

## Variants

Three build flavors are published from each upstream release:

| Variant | Tags | Ships |
|---------|------|-------|
| default (full) | `2.12.0+<date>`, `2.12`, `2`, `latest` | `toxiproxy-server` + `toxiproxy-cli` |
| client | `client-2.12.0+<date>`, `client-2.12`, … | `toxiproxy-cli` only |
| server | `server-2.12.0+<date>`, `server-2.12`, … | `toxiproxy-server` only |

A variant is a **plan entry, not a matrix dimension** — prepare, test and push
already run per variant, and one `smoke.star` covers all three. That is why
`versions.new_per_run` is a multiple of three: a run publishes whole versions,
never a version missing a variant.

Each variant declares its own `binaries` — a positive claim about the interface
surface, so the client bundle must not name `toxiproxy-server`. That is what
the three `metadata*.json` files are for.

## Platforms

`toxiproxy` publishes five platform entries per variant: both Linux arches,
both macOS arches and `windows/amd64`. There is **no `windows/arm64`** — no
variant ships one upstream, and declaring it would resolve zero assets and be
*silently skipped* rather than red.

Upstream builds toxiproxy as a pure-Go binary without cgo, so there is one
Linux build per arch and it is **fully static** — no `PT_INTERP`, no
`DT_NEEDED`, and no musl/glibc variants to choose between. `os.features` states
what an artifact requires *of the host*, so both Linux keys are **bare**:
tagging them `+libc.musl` would be a false requirement that hid them from every
glibc host. The `alpine:3.20` container leg in `mirror-base.yml` is what turns
that claim into evidence.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror-base.yml`, `toxiproxy/mirror.yml` | hand | yes — see below |
| `toxiproxy/{metadata*.json,CATALOG.md,logo.*}` | hand | — |
| `toxiproxy/tests/smoke.star` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci --spec toxiproxy/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

## Maintenance note — anonymous discovery

Shopify's GitHub org rejects the Actions installation `GITHUB_TOKEN` on its API
(authenticated `pipeline plan` returns exit 69; anonymous reads succeed). So:

- `toxiproxy/mirror.yml` sets `allow_manual_edits: true`, and no
  `verify-generated.yml` drift guard is emitted.
- The generated `discover` → *Plan versions* step has its
  `GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}` env **hand-removed** so
  release-listing runs unauthenticated (1 call per 6h poll, under the 60/h
  quota).

The step's own `Login to ghcr.io` is a **separate** credential path — it
authenticates reads of the *target's* tags via the docker native store, and
must be left in place.

**After any `ocx-mirror package pipeline generate ci`, re-remove that `env:`
block** — the generator re-adds it every time, and with the drift guard gone it
won't be flagged in CI.

## The binaries claim

Every variant puts its executables at the **content root** — the archive has no
wrapper dir (`strip_components: 0`) and the raw-binary variants are a single
file — so the only honest PATH entry is a bare `${installPath}`. `bin_scan`
only looks *below* an `${installPath}/<dir>` entry, so `auto`/`verify` is
rejected at spec load with exit 65. `mirror-base.yml` therefore sets
`bin_scan: off` and each `metadata*.json` hand-lists its own `binaries` — the
blessed shape for this asset type.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; each
package's redistribution license is recorded in [`NOTICE.md`](NOTICE.md).
