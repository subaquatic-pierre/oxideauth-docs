#!/usr/bin/env bash
#
# deploy.sh — Build the MkDocs site and deploy directly to GitHub Pages
# by force-pushing the build output to the gh-pages branch.
#
# Usage:
#   ./scripts/deploy.sh               # auto-increment patch version
#   ./scripts/deploy.sh minor         # bump minor version
#   ./scripts/deploy.sh major         # bump major version
#   ./scripts/deploy.sh 1.2.3         # use an explicit version tag
#   ./scripts/deploy.sh -y minor      # skip confirmation prompt
#
# The script builds the site with mkdocs build, then pushes the contents
# of site/ directly to the gh-pages branch — no CI pipeline required.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# ── helpers ────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # no color

log()  { printf "${GREEN}[deploy]${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}[deploy] WARNING:${NC} %s\n" "$*" >&2; }
err()  { printf "${RED}[deploy] ERROR:${NC} %s\n" "$*" >&2; exit 1; }

# ── pre-flight checks ─────────────────────────────────────────────────

command -v git >/dev/null 2>&1 || err "git is required but not found."
command -v mkdocs >/dev/null 2>&1 || err "mkdocs is required but not found."

if ! git diff-index --quiet HEAD --; then
  warn "Working tree is dirty. Commit or stash changes before deploying."
  exit 1
fi

CURRENT_BRANCH="$(git branch --show-current)"
if [ -z "$CURRENT_BRANCH" ]; then
  err "Not on any branch (detached HEAD). Checkout a branch first."
fi
log "Current branch: ${CURRENT_BRANCH}"

if [ "${CURRENT_BRANCH}" != "main" ]; then
  err "Not on main branch (current: ${CURRENT_BRANCH}). Switch to main first."
fi

# ── determine tag ─────────────────────────────────────────────────────

latest_tag() {
  git describe --tags --abbrev=0 2>/dev/null || echo "0.0.0"
}

LATEST="$(latest_tag)"
log "Latest tag: ${LATEST}"

YES=false

while [ $# -gt 0 ]; do
  case "$1" in
    -y|--yes) YES=true; shift ;;
    *)        break ;;
  esac
done

TAG=""

if [ $# -eq 0 ]; then
  BASE="${LATEST}"
  MAJOR="${BASE%%.*}"
  REST="${BASE#*.}"
  MINOR="${REST%%.*}"
  PATCH="${REST#*.}"
  NEW_PATCH=$((PATCH + 1))
  TAG="${MAJOR}.${MINOR}.${NEW_PATCH}"
elif [ $# -eq 1 ]; then
  case "$1" in
    major)
      BASE="${LATEST}"
      MAJOR="${BASE%%.*}"
      REST="${BASE#*.}"
      MINOR="${REST%%.*}"
      NEW_MAJOR=$((MAJOR + 1))
      TAG="${NEW_MAJOR}.0.0"
      ;;
    minor)
      BASE="${LATEST}"
      MAJOR="${BASE%%.*}"
      REST="${BASE#*.}"
      MINOR="${REST%%.*}"
      NEW_MINOR=$((MINOR + 1))
      TAG="${MAJOR}.${NEW_MINOR}.0"
      ;;
    patch)
      BASE="${LATEST}"
      MAJOR="${BASE%%.*}"
      REST="${BASE#*.}"
      MINOR="${REST%%.*}"
      PATCH="${REST#*.}"
      NEW_PATCH=$((PATCH + 1))
      TAG="${MAJOR}.${MINOR}.${NEW_PATCH}"
      ;;
    *)
      TAG="$1"
      ;;
  esac
else
  warn "Too many arguments. Usage: ./scripts/deploy.sh [-y] [major|minor|patch|X.Y.Z]"
  exit 4
fi

log "Deployment tag will be: ${TAG}"

# ── confirm ───────────────────────────────────────────────────────────

if [ "${YES}" = false ]; then
  read -r -p "$(printf "${YELLOW}Proceed with deploy tag ${TAG}?${NC} [y/N] ")" CONFIRM </dev/tty
  if [ "${CONFIRM}" != "y" ] && [ "${CONFIRM}" != "Y" ]; then
    log "Aborted."
    exit 0
  fi
fi

# ── build ─────────────────────────────────────────────────────────────

log "Building MkDocs site..."
if ! mkdocs build; then
  warn "Build failed."
  exit 2
fi

log "Build completed successfully."

# ── tag source branch ─────────────────────────────────────────────────

log "Creating tag ${TAG}..."
if ! git tag -a "${TAG}" -m "deploy: ${TAG}"; then
  warn "Failed to create tag ${TAG}. Tag may already exist locally."
  exit 3
fi

log "Pushing tag ${TAG} to origin..."
if ! git push origin "${TAG}"; then
  warn "Failed to push tag ${TAG} to origin."
  exit 3
fi

if ! git diff --quiet mkdocs.yml; then
  log "Committing version bump in mkdocs.yml..."
  git add mkdocs.yml
  git commit -m "chore: bump version to ${TAG}"
  git push origin "${CURRENT_BRANCH}"
fi

# ── deploy to gh-pages ────────────────────────────────────────────────

log "Deploying build output to gh-pages branch..."

TMP_DIR="$(mktemp -d)"
trap "rm -rf '${TMP_DIR}'" EXIT

cp -a site/. "${TMP_DIR}/"

cd "${TMP_DIR}"
git init -q
git checkout -B gh-pages
git add -A
git commit -m "deploy: ${TAG} [skip ci]" --allow-empty

GIT_REMOTE="$(git -C "${ROOT_DIR}" remote get-url origin)"
git push -f "${GIT_REMOTE}" gh-pages

cd "${ROOT_DIR}"

log "Deployed to gh-pages branch successfully."
log "Site will be live shortly."
