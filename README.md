# payments-service-grade-f

[![Lightwell library updates](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fanurag-saran%2Fpayments-service-grade-f%2Flightwell%2Fbadge%2Flightwell-badge.json&v=2)](https://github.com/anurag-saran/payments-service-grade-f/pulls?q=is%3Apr+is%3Aopen+label%3Alightwell)

Sibling of **[payments-service](https://github.com/anurag-saran/payments-service)** for the
**grade F / reachable break** live demo. Same app sources (including `ConfigLoader`
calling the snakeyaml constructor removed in 1.33), tests, Dockerfile, and deploy
manifests — used so upgrade-delta can show a **community** minor bump that headlines
**F** and **fails** `fail-on: D`.

Remediations come from the
**[Lightwell GitHub plugin](https://github.com/anurag-saran/lightwell-github-plugin-demo)**
(badge sync checks out that repo).

Not a production payments product. Package: `com.example.payments`.

## Why a separate repo?

| | payments-service | payments-service-notests | payments-service-grade-c | payments-service-grade-f |
|---|---|---|---|---|
| Hero | jackson drop-in → grade **B** | Empty tests → **REACHABILITY_ONLY** | json-path base bump → grade **C** | snakeyaml `1.30`→`1.33` → grade **F** |
| PipelineRun | `upgrade-delta-live-pr` | `upgrade-delta-live-pr-notests` | `upgrade-delta-live-pr-gradec` | `upgrade-delta-live-pr-gradef` |
| PVC | `upgrade-delta-live-reports` | `upgrade-delta-live-reports-notests` | `upgrade-delta-live-reports-gradec` | `upgrade-delta-live-reports-gradef` |
| Scorecard | Route `scorecard` | Route `scorecard-notests` | Route `scorecard-gradec` | Route `scorecard-gradef` |

Separate PVCs + viewers so concurrent demos never overwrite each other's reports.

Quiet **A** (json-path same-base remidiation) is slide evidence only — not a fifth live app.

## Build

JDK 17+.

```bash
mvn -B verify
# Equivalent (kept for pipeline scripts):
mvn -B -Pci-community verify
```

Produces a **fat / shaded** jar, CycloneDX `target/bom.json`, and JaCoCo under
`target/site/jacoco/`.

## Fast-lane demo (grade F)

On `main`, keep **community** snakeyaml `1.30`. Open a pom bump PR that moves to
community **`1.33` only** (do **not** bump json-path — that is the grade-C lane):

```bash
./scripts/demo-live-cycle.sh start
# …watch upgrade-delta-live-pr-gradef-… on the cluster…
# Expect: headline F → grade-gate fails
./scripts/demo-live-cycle.sh finish
```

Scorecard URL uses the **gradef** route host (see `.tekton/pull-request-live.yaml`).

Details: upgrade-delta `docs/DEMO-LIVE-POM.md`.

## Layout

- `pom.xml` / `src/` — same call sites and tests as payments-service (`ConfigLoader` → F)
- `coverage-map.json` — per-test coverage for fast-lane test selection
- `.upgrade-delta/` — vendored upgrade-delta live pipeline
- `.tekton/pull-request-live.yaml` — PaC trigger (`app-name: payments-service-grade-f`)
