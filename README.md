# sleep-iac

**Deployment truth for the sleep stack** — the ArgoCD app-of-apps, Helm values + version pins, and
the apps' infra CRs (Garage `Workspace`s, ESO `ExternalSecret`s, the `OpenRouterKey`, the agent
git-token). This is the middle of three layers (FU-025, homelab `docs/sleep-iac.md`):

```
app repos (sleep-tracking, snore-recorder)   code + chart only; publish image + OCI chart on a v* tag
        │  ghcr.io/teststuffstash/{sleep-ingester, charts/sleep-ingester}
        ▼
sleep-iac  (this repo)                        WHAT is deployed + at WHICH version — a deploy = a PR here
        │  ArgoCD reads it (public → no repo credential)
        ▼
homelab (the platform)                        operators, the `sleep` AppProject, one root Application → here
```

App repos know nothing about homelab; homelab knows nothing about sleep versions. **A deploy is a
reviewable version-bump PR in this repo** (Renovate opens it, CI + the reviewer gate it, ArgoCD
syncs it) — no `tofu apply`, no click-ops.

## Layout

| Path | What |
|---|---|
| `apps/` | the child ArgoCD `Application`s (the app-of-apps content; `project: sleep`) |
| `values/sleep-ingester.yaml` | the ingester's Helm values — **image tag + config; the version pin** |
| `sleep-tracking/` | sleep-tracking's infra CRs (Garage Workspace, ESO secrets, OpenRouterKey) |
| `sleep-tracking/agent/` | the coding agent's per-repo bits (git-token, uv-cache) — **kubectl-applied**, not in the ArgoCD sync (`recurse:false`) |
| `snore-recorder/` | snore-recorder's Garage Workspace |

## How a deploy works

The ingester chart is published to `ghcr.io/teststuffstash/charts` on a `v*` tag in the
sleep-tracking repo (chart version == appVersion == git tag). To deploy that release, bump **both**
`apps/sleep-ingester.yaml` `targetRevision` **and** `values/sleep-ingester.yaml` `image.tag` (CI
asserts they match). Renovate raises this as one grouped PR (`renovate.json`).

## CI

`devbox run ci` (`scripts/ci.sh`) — yamllint, `kubeconform` (CRDs → ignore-missing-schemas), the
chart==tag lockstep check, and a `helm template` of the pinned chart against the values. Same gate
locally and in `.github/workflows/ci.yaml` (`runs-on: homelab-ephemeral`); `ci` is the required
check.

## Observe (from the homelab repo, which holds the kubeconfig)

```sh
kubectl -n argocd get applications -l argocd.argoproj.io/instance   # sleep-tracking/-ingester/snore-recorder
kubectl get workspace                                              # sleep-tracking-garage, snore-recorder-garage (Synced/Ready)
```
