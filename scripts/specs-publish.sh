#!/usr/bin/env bash
# specs-publish.sh — build and publish sleep-tracking's spec site to the
# sleep-specs Garage bucket. Called by the specs-publish GitHub Actions workflow
# on merge to master of the sleep-tracking repo.
#
# Usage: specs-publish.sh <specs-dir>
#   <specs-dir>  path to the sleep-tracking specs/ tree (the built site)
#
# Environment (set by the workflow from the Workspace connection Secret):
#   S3_ENDPOINT   — Garage S3 endpoint (default: https://s3.teststuff.net)
#   S3_REGION     — Garage region (default: garage)
#   AWS_ACCESS_KEY_ID     — writer key id (from sleep-specs-garage-conn)
#   AWS_SECRET_ACCESS_KEY — writer key secret (from sleep-specs-garage-conn)
set -euo pipefail

SPECS_DIR="${1:?usage: specs-publish.sh <specs-dir>}"
S3_ENDPOINT="${S3_ENDPOINT:-https://s3.teststuff.net}"
S3_REGION="${S3_REGION:-garage}"
BUCKET="sleep-specs"

if [ ! -d "$SPECS_DIR" ]; then
  echo "::error::specs directory not found: $SPECS_DIR"
  exit 1
fi

if [ -z "${AWS_ACCESS_KEY_ID:-}" ] || [ -z "${AWS_SECRET_ACCESS_KEY:-}" ]; then
  echo "::error::AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY must be set"
  exit 1
fi

echo "==> Publishing spec site to s3://$BUCKET (endpoint: $S3_ENDPOINT)"

aws s3 sync "$SPECS_DIR" "s3://$BUCKET" \
  --endpoint-url "$S3_ENDPOINT" \
  --region "$S3_REGION" \
  --delete \
  --no-progress

echo "✓ Spec site published to s3://$BUCKET"