#!/bin/bash
# release-milestone.sh - Tag every merged PR shipped in a stable release with
# a milestone named after it, so a PR page shows which version it went out in.
#
# Usage: scripts/release-milestone.sh <stable-tag> [--dry-run]
#   e.g. scripts/release-milestone.sh v1.0.0 --dry-run
#
# Range = previous stable tag..<stable-tag>; beta tags are skipped. In desktop
# a promoted stable tag points at the beta snapshot (not main HEAD), so the
# tag range is exactly what shipped.
# A PR counts when the commit GitHub recorded as its merge commit (the squash
# commit, the last rebased commit, or the merge commit) is in that range;
# commits pushed straight to main have no PR and are skipped.
#
# Idempotent: re-running re-applies the same milestone. Runs in release.yml
# after publish (stable only), or locally with an authenticated `gh` to
# backfill older releases. GH_REPO overrides the target repository.
#
# The same file lives in desktop, cli and skills; keep the copies identical.

set -euo pipefail

log() { echo "[$(date '+%H:%M:%S')] [milestone] $*"; }

TAG="${1:-}"
DRY_RUN=false
[ "${2:-}" = "--dry-run" ] && DRY_RUN=true

if ! [[ "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Usage: $0 <stable-tag> [--dry-run]   (e.g. v1.0.0; beta tags are not milestoned)" >&2
  exit 1
fi
git rev-parse -q --verify "refs/tags/$TAG" >/dev/null || { echo "Tag $TAG not found locally — fetch tags first" >&2; exit 1; }

REPO="${GH_REPO:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"

# Previous stable tag = the one right below TAG in version order.
PREV_TAG=$(git tag --list 'v*' --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
  | awk -v t="$TAG" 'found { print; exit } $0 == t { found = 1 }')
if [ -z "$PREV_TAG" ]; then
  log "No stable tag before $TAG — nothing to compare against, skipping"
  exit 0
fi
log "Release $TAG, range $PREV_TAG..$TAG ($REPO)"

# A PR shipped in this release iff its merge commit is in the range. Only PRs
# merged after the fork point can qualify; a day of slack absorbs clock skew.
RANGE_SHAS=$(git rev-list "$PREV_TAG..$TAG")
SINCE_TS=$(( $(git log -1 --format=%ct "$(git merge-base "$PREV_TAG" "$TAG")") - 86400 ))
# GNU date (CI) takes -d @ts, BSD date (macOS) takes -r ts.
SINCE=$(date -u -d "@$SINCE_TS" +%Y-%m-%d 2>/dev/null || date -u -r "$SINCE_TS" +%Y-%m-%d)
PRS=$(gh pr list --repo "$REPO" --state merged --search "merged:>=$SINCE" --limit 1000 \
    --json number,mergeCommit --jq '.[] | "\(.number) \(.mergeCommit.oid)"' \
  | while read -r number oid; do
      if grep -qx "$oid" <<<"$RANGE_SHAS"; then echo "$number"; fi
    done | sort -n)

if [ -z "$PRS" ]; then
  log "No merged PRs in range, skipping"
  exit 0
fi
log "PRs shipped in $TAG: $(tr '\n' ' ' <<<"$PRS")"

if [ "$DRY_RUN" = true ]; then
  log "Dry run — no milestone created or assigned"
  exit 0
fi

# Find or create the milestone (closed ones included, so re-runs reuse it).
MILESTONE=$(gh api --paginate "repos/$REPO/milestones?state=all&per_page=100" \
  --jq ".[] | select(.title == \"$TAG\") | .number" | sed -n 1p)
if [ -z "$MILESTONE" ]; then
  MILESTONE=$(gh api -X POST "repos/$REPO/milestones" -f title="$TAG" --jq .number)
  log "Created milestone $TAG (#$MILESTONE)"
fi

# The issues endpoint (not `gh pr edit`) accepts closed milestones by number.
for pr in $PRS; do
  gh api -X PATCH "repos/$REPO/issues/$pr" -F milestone="$MILESTONE" --silent
  log "  #$pr -> $TAG"
done

gh api -X PATCH "repos/$REPO/milestones/$MILESTONE" -f state=closed --silent
log "Done: $(echo "$PRS" | wc -l | tr -d ' ') PRs milestoned, milestone $TAG closed"
