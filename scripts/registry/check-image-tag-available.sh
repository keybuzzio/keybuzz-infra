#!/usr/bin/env bash
# PH-SAAS-T8.12AS.10 (KEY-309) -- Registry tag availability guard
#
# Verifies whether a given Docker image tag already exists in a remote registry
# (typically ghcr.io). This is a READ-ONLY check: it never pushes, never deletes,
# never modifies any image.
#
# Use this script BEFORE any docker push to enforce the KeyBuzz tag discipline:
#   one tag = one source = one digest.
# If the tag is already present in the registry, the push MUST NOT happen
# without an explicit Ludovic GO + a documented exception (cf DOCKER-TAG-DISCIPLINE.md).
#
# Usage:
#   scripts/registry/check-image-tag-available.sh <image-with-tag>
#
# Example:
#   scripts/registry/check-image-tag-available.sh ghcr.io/keybuzzio/keybuzz-client:v3.5.999-test-dev
#
# Exit codes:
#   0  tag is AVAILABLE (does not exist in the registry) -> safe to docker push
#   1  tag is TAKEN (already exists in the registry) -> STOP before push
#   2  error (usage, missing docker, auth failure, network failure, or unknown)

set -u

IMAGE="${1:-}"

usage() {
  cat <<'USAGE'
Usage: scripts/registry/check-image-tag-available.sh <image-with-tag>

  Example:
    scripts/registry/check-image-tag-available.sh ghcr.io/keybuzzio/keybuzz-client:v3.5.999-test-dev

  Exit codes:
    0  tag AVAILABLE (safe to push)
    1  tag TAKEN (STOP before push)
    2  error (usage, missing docker, auth/network failure)
USAGE
}

if [ -z "$IMAGE" ]; then
  printf 'FATAL: missing required argument <image-with-tag>\n\n' >&2
  usage >&2
  exit 2
fi

case "$IMAGE" in
  -h|--help|help) usage; exit 0 ;;
esac

# Image must contain a tag (a colon after the last slash)
case "$IMAGE" in
  */*:* | *:*) : ;;
  *) printf 'FATAL: image must include a tag (got: %s)\n\n' "$IMAGE" >&2; usage >&2; exit 2 ;;
esac

if ! command -v docker >/dev/null 2>&1; then
  printf 'FATAL: docker not found on PATH; this guard requires docker to call manifest inspect\n' >&2
  exit 2
fi

# Run docker manifest inspect in read-only mode. We capture stderr separately
# so we can distinguish a clean "manifest unknown" (tag absent) from an auth or
# network failure.
TMP_STDERR="$(mktemp 2>/dev/null || mktemp -t taggrdXXXX)"
docker manifest inspect "$IMAGE" >/dev/null 2>"$TMP_STDERR"
RC=$?
ERR_OUTPUT="$(cat "$TMP_STDERR" 2>/dev/null || true)"
rm -f "$TMP_STDERR"

if [ "$RC" -eq 0 ]; then
  printf '[TAG-GUARD] FAIL: tag is TAKEN in registry: %s\n' "$IMAGE"
  printf '[TAG-GUARD] STOP before any docker push. See keybuzz-infra/docs/DOCKER-TAG-DISCIPLINE.md\n'
  exit 1
fi

# Tag absent? typical messages:
#   - "manifest unknown"
#   - "no such manifest"
#   - "errors: ... MANIFEST_UNKNOWN"
#   - HTTP 404
if printf '%s' "$ERR_OUTPUT" | grep -qiE 'manifest unknown|no such manifest|MANIFEST_UNKNOWN|404 not found|404 page not found'; then
  printf '[TAG-GUARD] OK: tag is AVAILABLE in registry: %s\n' "$IMAGE"
  printf '[TAG-GUARD] You may proceed with docker push. After push, document the digest + OCI revision label in the phase report.\n'
  exit 0
fi

# Other failures (auth, network, repository unknown, etc.) -> exit 2 (error)
printf '[TAG-GUARD] ERROR: cannot determine availability of %s\n' "$IMAGE" >&2
printf '[TAG-GUARD] docker manifest inspect exit=%s stderr (first 400 chars):\n' "$RC" >&2
printf '%s\n' "$ERR_OUTPUT" | head -c 400 >&2
printf '\n[TAG-GUARD] Common causes: not logged in to the registry, registry unreachable, repository name typo.\n' >&2
exit 2
