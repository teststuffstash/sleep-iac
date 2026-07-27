# sleep-iac review rubric (appended to the reviewer's system prompt)

This repo is the sleep stack's DEPLOY WRAPPER — GitOps manifests only. PROD-SERVING: a merged
change syncs to the live cluster within minutes (ArgoCD automated+selfHeal). Review posture:

- BLOCKING: a literal secret/credential value anywhere (references only — existingSecret/ESO);
  a hand-edited chart pin outside the deploy pipeline (unless the PR says why); a manifest that
  fails render/validate; deleting an Application without its data story (PVCs/buckets orphan).
- The wrapper stays PLATFORM-SPECIFIC and the app charts stay target-agnostic — provisioning
  (claims, ExternalSecrets) belongs HERE, never pushed up into an app chart (homelab
  platform-and-stacks.md §Composition axes).
- Follow-ups over blocking for: naming nits, comment gaps, non-load-bearing duplication.
