#!/usr/bin/env bash
# ci.sh — the sleep-iac gate. This repo is the sleep stack's deployment truth (app-of-apps +
# infra CRs + version pins), so the gate is: lint the YAML, structurally validate the manifests,
# and prove the pinned ingester chart actually renders with our values. Thin seam — the workflow
# just calls `devbox run ci`, so logic + tool versions live here, not in CI YAML. Run it locally
# the same way: `devbox run ci`.
set -euo pipefail

DIRS="apps values sleep-tracking snore-recorder"

echo "==> yamllint"
yamllint $DIRS

echo "==> kubeconform (manifests; CRDs → ignore-missing-schemas)"
# The infra CRs are CRDs (Workspace, ExternalSecret, OpenRouterKey, GithubAccessToken) + ArgoCD
# Applications — kubeconform has no schema for those, so -ignore-missing-schemas skips them and
# still hard-validates the core kinds (Job, PVC, ConfigMap). agent/ is validated too.
kubeconform -summary -strict -ignore-missing-schemas apps sleep-tracking snore-recorder

# --- the version pins are the whole point of this repo: assert chart == image tag, then prove the
#     pinned chart actually renders with our values. ---
PIN=$(awk '/targetRevision:/{print $2; exit}' apps/sleep-ingester.yaml)
IMG=$(awk '/^[[:space:]]+tag:/{gsub(/"/,"",$2); print $2; exit}' values/sleep-ingester.yaml)
echo "==> version pins: chart targetRevision=$PIN, image.tag=$IMG"
if [ "$PIN" != "$IMG" ]; then
  echo "✗ chart targetRevision ($PIN) != image.tag ($IMG) — they move together; bump both" >&2
  exit 1
fi

echo "==> helm template (pinned ingester chart + values) | kubeconform"
helm template sleep-ingester "oci://ghcr.io/teststuffstash/charts/sleep-ingester" \
  --version "$PIN" -f values/sleep-ingester.yaml \
  | kubeconform -summary -strict -ignore-missing-schemas -

echo "✓ sleep-iac validation passed"
