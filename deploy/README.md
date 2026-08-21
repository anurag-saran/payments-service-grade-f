# Demo Deployments (stable + canary)

Apply once to the OpenShift demo namespace so the live pipeline can shift traffic:

```bash
oc apply -f deploy/30-payments-canary.yaml -n upgrade-delta-demo
```

| Object | Role |
|---|---|
| `Deployment/payments-stable` | Baseline traffic (weight 100 initially) |
| `Deployment/payments-canary` | Scaled up by `canary-rollout`; starts at 0 replicas |
| `Service/payments-*` | Separate selectors so synthetic probes hit canary only |
| `Route/payments-service` | Weighted `to` + `alternateBackends` for progressive canary |

Images are built by the Tekton Task `build-payments-image` (OpenShift binary BuildConfig)
from this repo’s `Dockerfile`.
