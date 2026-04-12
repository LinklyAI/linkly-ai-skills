#!/usr/bin/env bash
# package.sh - Release script for Linkly AI Skills
# Packages, tags, pushes, and creates a GitHub Release with the ZIP asset.
#
# Usage:
#   ./scripts/package.sh          # interactive release flow
#   ./scripts/package.sh --zip    # only build the ZIP, skip release

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
ZIP_FILE=""
ZIP_ONLY=false

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ============================================================================
# Helper Functions
# ============================================================================

print_ok() { echo -e "  ${GREEN}✓${NC} $1"; }
print_err() { echo -e "  ${RED}✗${NC} $1"; }
print_step() { echo -e "\n${BOLD}$1${NC}"; }

build_zip() {
  ZIP_FILE="$ROOT_DIR/linkly-skills-latest.zip"
  rm -f "$ZIP_FILE"

  cd "$ROOT_DIR"
  zip -r "$ZIP_FILE" \
    SKILL.md \
    references/ \
    LICENSE \
    -x "**/.DS_Store" "**/__pycache__/*" > /dev/null

  print_ok "linkly-ai.zip ($(du -h "$ZIP_FILE" | cut -f1 | xargs))"
}

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

update_version_in_files() {
  # Update version badge in README.md
  sed -i '' "s/version-$CURRENT_VERSION-blue/version-$NEW_VERSION-blue/" "$ROOT_DIR/README.md"
}

confirm_and_execute() {
  print_step "Step 4: Confirm"
  echo -e "  Version : ${BOLD}$CURRENT_VERSION -> $NEW_VERSION${NC}"
  echo -e "  Tag     : v$NEW_VERSION"
  echo -e "  Asset   : linkly-ai.zip"
  echo -e "  Actions : bump version -> commit -> tag -> push -> gh release"
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

  # -- Build ZIP --
  echo -n "  Building ZIP... "
  build_zip

  # -- Commit & Tag --
  echo -n "  Committing and tagging... "
  cd "$ROOT_DIR"
  git add README.md
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

  # -- Create GitHub Release --
  echo -n "  Creating GitHub Release... "
  local notes
  local last_tag
  last_tag=$(git describe --tags --abbrev=0 "v$NEW_VERSION^" 2>/dev/null || echo "")
  if [[ -n "$last_tag" ]]; then
    notes=$(git log "${last_tag}..v$NEW_VERSION" --pretty=format:"- %s" --no-merges)
  else
    notes=$(git log "v$NEW_VERSION" --pretty=format:"- %s" --no-merges)
  fi

  gh release create "v$NEW_VERSION" "$ZIP_FILE#linkly-ai-skills-v${NEW_VERSION}.zip" \
    --title "v$NEW_VERSION" \
    --notes "$notes" \
    > /dev/null 2>&1
  echo -e "${GREEN}OK${NC}"

  # -- Done (keep ZIP for manual R2 upload) --

  echo ""
  echo -e "  ${GREEN}${BOLD}Released v$NEW_VERSION${NC}"
  echo -e "  ${DIM}https://github.com/LinklyAI/linkly-ai-skills/releases/tag/v$NEW_VERSION${NC}"
}

# ============================================================================
# Main
# ============================================================================

# Parse args
if [[ "${1:-}" == "--zip" ]]; then
  ZIP_ONLY=true
fi

echo ""
echo -e "${BOLD}Linkly AI Skills Release${NC}"
echo "────────────────────────"

if $ZIP_ONLY; then
  print_step "Build ZIP only"
  build_zip
  echo ""
  echo -e "  Output: ${BOLD}$ZIP_FILE${NC}"
else
  check_workdir
  select_version
  show_release_notes
  confirm_and_execute
fi
