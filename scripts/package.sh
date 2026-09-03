#!/usr/bin/env bash
# package.sh - Release script for Linkly AI Skills
# Bumps the version in the three places that carry it, commits, tags and pushes.
# Packaging and publishing are done by .github/workflows/release.yml, which the
# pushed tag triggers -- building the ZIP locally as well would produce two
# artifacts for the same version and make failures hard to attribute.
#
# Usage:
#   ./scripts/package.sh          # interactive release flow

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# State
CURRENT_VERSION=""
NEW_VERSION=""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ============================================================================
# Helper Functions
# ============================================================================

print_ok() { echo -e "  ${GREEN}✓${NC} $1"; }
print_err() { echo -e "  ${RED}✗${NC} $1"; }
print_step() { echo -e "\n${BOLD}$1${NC}"; }

# ============================================================================
# Steps
# ============================================================================

check_workdir() {
  print_step "Step 1: Preflight Check"

  if [[ -n $(git -C "$ROOT_DIR" status -s) ]]; then
    print_err "Working directory has uncommitted changes"
    git -C "$ROOT_DIR" status -s
    exit 1
  fi
  print_ok "Working directory clean"

  if ! command -v gh &> /dev/null; then
    print_err "gh CLI is required (brew install gh)"
    exit 1
  fi
  print_ok "gh CLI available"

  # Read current version from latest git tag
  CURRENT_VERSION=$(git -C "$ROOT_DIR" describe --tags --abbrev=0 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "0.0.0")
  print_ok "Current version: $CURRENT_VERSION"
}

select_version() {
  print_step "Step 2: Select Version"

  IFS='.' read -r major minor patch <<< "$CURRENT_VERSION"
  local patch_ver="$major.$minor.$((patch + 1))"
  local minor_ver="$major.$((minor + 1)).0"
  local major_ver="$((major + 1)).0.0"

  echo "  1) patch  -> $patch_ver"
  echo "  2) minor  -> $minor_ver"
  echo "  3) major  -> $major_ver"
  echo ""
  read -r -p "  Select [1-3]: " choice

  case "$choice" in
    1) NEW_VERSION="$patch_ver" ;;
    2) NEW_VERSION="$minor_ver" ;;
    3) NEW_VERSION="$major_ver" ;;
    *) print_err "Invalid choice"; exit 1 ;;
  esac

  print_ok "$CURRENT_VERSION -> $NEW_VERSION"
}

show_release_notes() {
  print_step "Step 3: Release Notes"

  local last_tag notes
  last_tag=$(git -C "$ROOT_DIR" describe --tags --abbrev=0 2>/dev/null || echo "")

  if [[ -n "$last_tag" ]]; then
    notes=$(git -C "$ROOT_DIR" log "${last_tag}..HEAD" --pretty=format:"- %s" --no-merges)
    echo -e "  ${DIM}Since $last_tag:${NC}"
  else
    notes=$(git -C "$ROOT_DIR" log --pretty=format:"- %s" --no-merges -20)
    echo -e "  ${DIM}All commits:${NC}"
  fi

  echo "$notes" | sed 's/^/  /'
}

# The version lives in three files. release.yml asserts all three agree with the
# tag, so any place missed here fails the release instead of shipping a mismatch.
update_version_in_files() {
  # README badge
  sed -i '' "s/version-$CURRENT_VERSION-blue/version-$NEW_VERSION-blue/" "$ROOT_DIR/README.md"
  # SKILL.md frontmatter
  sed -i '' "s/^version: $CURRENT_VERSION$/version: $NEW_VERSION/" "$ROOT_DIR/SKILL.md"
  # SKILL.md body marker -- the authoritative one: some platforms strip
  # frontmatter keys they do not recognise, body text always travels with the file
  sed -i '' "s/^linkly-ai-skill-version: $CURRENT_VERSION$/linkly-ai-skill-version: $NEW_VERSION/" "$ROOT_DIR/SKILL.md"
}

confirm_and_execute() {
  print_step "Step 4: Confirm"
  echo -e "  Version : ${BOLD}$CURRENT_VERSION -> $NEW_VERSION${NC}"
  echo -e "  Tag     : v$NEW_VERSION"
  echo -e "  Actions : bump version -> commit -> tag -> push"
  echo -e "  Then    : release.yml packages, uploads to R2 and creates the GitHub Release"
  echo ""
  read -r -p "  Type 'yes' to release: " response
  if [[ "$response" != "yes" ]]; then
    echo "  Cancelled."
    exit 0
  fi

  # -- Bump version --
  echo ""
  echo -n "  Updating versions... "
  update_version_in_files
  echo -e "${GREEN}OK${NC}"

  # -- Commit & Tag --
  echo -n "  Committing and tagging... "
  cd "$ROOT_DIR"
  git add README.md SKILL.md
  git commit -m "chore: release v$NEW_VERSION" > /dev/null
  git tag "v$NEW_VERSION"
  echo -e "${GREEN}OK${NC}"

  # -- Push --
  echo -n "  Pushing to origin... "
  if ! git push origin main 2>/dev/null; then
    echo -e "${RED}FAILED${NC}"
    echo ""
    echo "  Manual recovery:"
    echo "    git push origin main"
    echo "    git push origin v$NEW_VERSION"
    exit 1
  fi
  if ! git push origin "v$NEW_VERSION" 2>/dev/null; then
    echo -e "${RED}FAILED${NC}"
    echo ""
    echo "  Manual recovery:"
    echo "    git push origin v$NEW_VERSION"
    exit 1
  fi
  echo -e "${GREEN}OK${NC}"

  echo ""
  echo -e "  ${GREEN}${BOLD}Tagged v$NEW_VERSION${NC}"
  echo -e "  ${DIM}release.yml is now packaging and publishing it:${NC}"
  echo -e "  ${DIM}https://github.com/LinklyAI/linkly-ai-skills/actions${NC}"
}

# ============================================================================
# Main
# ============================================================================

echo ""
echo -e "${BOLD}Linkly AI Skills Release${NC}"
echo "────────────────────────"

check_workdir
select_version
show_release_notes
confirm_and_execute
