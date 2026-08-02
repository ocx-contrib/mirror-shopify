# NOTICE

This repository packages and redistributes upstream software published by
[Shopify](https://github.com/Shopify). The Apache-2.0 license in
[`LICENSE`](LICENSE) covers the OCX pipeline files authored here. It does
**not** cover any upstream-derived asset — each package's redistributed bytes
carry their own license, recorded below.

Each package's logo is reproduced for catalog identification only, under
nominative fair use. The marks remain the property of their respective owners
and no endorsement is implied.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `toxiproxy` | `ghcr.io/ocx-contrib/shopify/toxiproxy` | `MIT` |

---

## `toxiproxy`

Upstream: <https://github.com/Shopify/toxiproxy>
Published to `ghcr.io/ocx-contrib/shopify/toxiproxy`.

| Component | SPDX | Holder |
|---|---|---|
| Toxiproxy (`toxiproxy-server`, `toxiproxy-cli`) | **MIT** | Copyright (c) 2014 Shopify Inc. |

Permissive; redistribution of the compiled binaries is granted provided the
copyright notice and permission notice are retained. The `.tar.gz` assets the
default variant re-bundles ship upstream's own `LICENSE` file, which is carried
through byte-for-byte; the raw-binary `client` and `server` variants do not, so
the terms are those of
<https://github.com/Shopify/toxiproxy/blob/main/LICENSE>. The published
binaries statically link third-party Go modules under permissive licenses,
enumerated in upstream's `go.mod`.

The Toxiproxy name is a Shopify Inc. trademark, used for catalog identification
under nominative fair use. The logo shipped with this package is an
OCX-authored mark, not an official Toxiproxy or Shopify asset.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.
