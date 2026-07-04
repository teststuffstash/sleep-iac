# sleep-iac

**Deployment truth for the sleep stack** — the ArgoCD app-of-apps, Helm values + version pins, and
the apps' infra CRs (Garage `Workspace`s, ESO `ExternalSecret`s, the `OpenRouterKey`, the agent
git-token). This is the middle of three layers (FU-025, homelab `docs/sleep-iac.md`):

```
app repos (sleep-tracking, snore-recorder)   code + chart only; on an app-relevant master push, build
        │                                     image + chart at one version 2026.<m>.<d>-g<sha> → ghcr
        │  ghcr.io/teststuffstash/{sleep-ingester, charts/sleep-ingester}   … and open a bump PR here
        ▼
sleep-iac  (this repo)                        WHICH chart version is deployed — a deploy = a PR here
        │  ArgoCD reads it (public → no repo credential)
        ▼
homelab (the platform)                        operators, the `sleep` AppProject, one root Application → here
```

App repos know nothing about homelab; homelab knows nothing about sleep versions. **A deploy is a
version-bump PR in this repo** — the sleep-tracking `deploy` workflow opens it automatically, CI
gates it, ArgoCD syncs it. No `tofu apply`, no click-ops. sleep-iac pins **only the chart version**;
the image tag defaults to the chart appVersion, so image versions never appear here.

## Layout

| Path | What |
|---|---|
| `apps/` | the child ArgoCD `Application`s (the app-of-apps content; `project: sleep`) |
| `values/sleep-ingester.yaml` | the ingester's Helm values — run config only (**no image block**; tag = chart appVersion) |
| `sleep-tracking/` | sleep-tracking's infra CRs (Garage Workspace, ESO secrets, OpenRouterKey) |
| `sleep-tracking/agent/` | the coding agent's per-repo bits (git-token, uv-cache) — **kubectl-applied**, not in the ArgoCD sync (`recurse:false`) |
| `snore-recorder/` | snore-recorder's Garage Workspace |

## How a deploy works

An app-relevant push to sleep-tracking `master` runs its `deploy` workflow, which builds the image
+ packages the chart at one version `2026.<m>.<d>-g<sha>` (chart version == appVersion == image tag)
and opens/updates the single deploy PR here (branch `deploy/sleep-ingester`) bumping
`apps/sleep-ingester.yaml` `targetRevision`. That's the **only** knob — the image tag defaults to the
chart appVersion, so `values/` never sets it. CI + auto-merge land the PR; ArgoCD syncs. Rollback or
roll-forward = bump `targetRevision` to another published chart version. Full design + the one-time
cross-repo token/App setup: homelab `docs/sleep-iac.md` §"Deploy pipeline".

## CI

`devbox run ci` (`scripts/ci.sh`) — yamllint, `kubeconform` (CRDs → ignore-missing-schemas, plus a
`kustomize build` of `sleep-tracking/`), and a `helm template` of the pinned chart against the
values. Same gate locally and in `.github/workflows/ci.yaml` (`runs-on: homelab-ephemeral`); `ci` is
the required check.

## Observe (from the homelab repo, which holds the kubeconfig)

```sh
kubectl -n argocd get applications -l argocd.argoproj.io/instance   # sleep-tracking/-ingester/snore-recorder
kubectl get workspace                                              # sleep-tracking-garage, snore-recorder-garage (Synced/Ready)
```
