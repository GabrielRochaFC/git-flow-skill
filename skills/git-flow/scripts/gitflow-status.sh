#!/usr/bin/env bash
# gitflow-status.sh — READ-ONLY diagnosis for the git-flow skill.
# Does not change anything in the repository. Usage: bash scripts/gitflow-status.sh
set -u

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "REPO: no git repository found here."
  echo "ACTION: see references/setup.md (section 'No repository')."
  exit 0
fi

cd "$(git rev-parse --show-toplevel)" || exit 1
ROOT=$(pwd)

# ---------- helpers ----------
has_local()  { git show-ref --verify --quiet "refs/heads/$1"; }
has_remote() { git show-ref --verify --quiet "refs/remotes/origin/$1"; }
mark()       { if "$1" "$2"; then echo "yes"; else echo "no"; fi; }

# cfg KEY DEFAULT  -> value from .gitflow (an explicit empty value is accepted) or DEFAULT
cfg() {
  if [ -f .gitflow ] && grep -Eq "^[[:space:]]*$1[[:space:]]*=" .gitflow; then
    grep -E "^[[:space:]]*$1[[:space:]]*=" .gitflow | tail -n1 \
      | sed -E 's/^[^=]*=//; s/[[:space:]]*#.*$//; s/^[[:space:]]+//; s/[[:space:]]+$//'
  else
    echo "$2"
  fi
}

CFG_SRC="autodetected"
[ -f .gitflow ] && CFG_SRC=".gitflow"

detect_main() {
  for b in main master; do
    if has_local "$b" || has_remote "$b"; then echo "$b"; return; fi
  done
  echo "main"
}

detect_vfile() {
  for f in package.json pyproject.toml Cargo.toml composer.json VERSION; do
    if [ -f "$f" ]; then echo "$f"; return; fi
  done
  echo ""
}

# ---------- tags ----------
LAST_TAG=$(git tag --list --sort=-v:refname 2>/dev/null | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
TAG_COUNT=$(git tag --list 2>/dev/null | wc -l | tr -d ' ')

DEFAULT_PREFIX=""
case "$LAST_TAG" in v*) DEFAULT_PREFIX="v" ;; esac

# ---------- configuration ----------
MAIN=$(cfg MAIN_BRANCH "$(detect_main)")
DEV=$(cfg DEVELOP_BRANCH "develop")
PREFIX=$(cfg TAG_PREFIX "$DEFAULT_PREFIX")
VFILE=$(cfg VERSION_FILE "$(detect_vfile)")
FEATURE_MERGE=$(cfg FEATURE_MERGE "pr")
CHANGELOG=$(cfg CHANGELOG "false")
GH_RELEASE=$(cfg GITHUB_RELEASE "true")

read_version() {
  [ -n "$VFILE" ] && [ -f "$VFILE" ] || return 0
  case "$VFILE" in
    *package.json|*composer.json)
      grep -m1 -E '"version"[[:space:]]*:' "$VFILE" \
        | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' ;;
    *pyproject.toml|*Cargo.toml)
      grep -m1 -E '^[[:space:]]*version[[:space:]]*=' "$VFILE" \
        | sed -E 's/.*=[[:space:]]*"([^"]+)".*/\1/' ;;
    *VERSION)
      head -n1 "$VFILE" | tr -d '[:space:]' ;;
  esac
}
FILE_VERSION=$(read_version)

# ---------- report ----------
CUR_BRANCH=$(git symbolic-ref --short -q HEAD || echo "(detached HEAD)")
DIRTY_COUNT=$(git status --porcelain | wc -l | tr -d ' ')
REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)
HAS_COMMITS="yes"
git rev-parse --verify -q HEAD >/dev/null 2>&1 || HAS_COMMITS="no"

echo "== Git Flow: diagnosis =="
echo "repository:        $ROOT"
echo "current branch:    $CUR_BRANCH"
if [ "$DIRTY_COUNT" = "0" ]; then
  echo "working tree:      clean"
else
  echo "working tree:      DIRTY ($DIRTY_COUNT changed file(s)) -> resolve before merging"
fi
echo "has commits:       $HAS_COMMITS"
echo "remote origin:     ${REMOTE_URL:-none}"
echo

echo "== Conventions (source: $CFG_SRC) =="
echo "production branch:   $MAIN"
echo "integration branch:  $DEV"
echo "tag prefix:          '${PREFIX}' (e.g. ${PREFIX}1.2.0)"
echo "version file:        ${VFILE:-none (version lives only in the tag)}"
echo "feature -> develop:  $FEATURE_MERGE"
echo "CHANGELOG.md:        $CHANGELOG"
echo "GitHub Release:      $GH_RELEASE"
echo

echo "== Branches =="
printf "%-22s local: %-4s remote: %s\n" "$MAIN" "$(mark has_local "$MAIN")" "$(mark has_remote "$MAIN")"
printf "%-22s local: %-4s remote: %s\n" "$DEV"  "$(mark has_local "$DEV")"  "$(mark has_remote "$DEV")"
OPEN=$(git for-each-ref --format='%(refname:short)' \
  refs/heads/release/ refs/heads/hotfix/ \
  refs/remotes/origin/release/ refs/remotes/origin/hotfix/ 2>/dev/null)
if [ -n "$OPEN" ]; then
  echo "open releases/hotfixes:"
  echo "$OPEN" | sed 's/^/  - /'
else
  echo "open releases/hotfixes: none"
fi
FEATS=$(git for-each-ref --format='%(refname:short)' refs/heads/feature/ 2>/dev/null | wc -l | tr -d ' ')
echo "local features:      $FEATS"
echo

echo "== Version =="
echo "tags in repo:        $TAG_COUNT"
echo "last SemVer tag:     ${LAST_TAG:-none}"
echo "version in file:     ${FILE_VERSION:-n/a}"
if [ -n "$LAST_TAG" ] && [ "$DEFAULT_PREFIX" != "$PREFIX" ]; then
  echo "WARNING: existing tags use prefix '${DEFAULT_PREFIX}' but the configuration uses '${PREFIX}'. Align with the team before creating new tags."
fi
if [ -n "$LAST_TAG" ] && [ -n "$FILE_VERSION" ]; then
  TAG_CORE=${LAST_TAG#v}
  if [ "$TAG_CORE" != "$FILE_VERSION" ]; then
    echo "WARNING: tag ($TAG_CORE) != version in file ($FILE_VERSION). On develop the file should equal the latest release; an incomplete release may be pending."
  fi
fi
echo

# ---------- commits since the last tag + suggestion ----------
REF=""
if has_local "$DEV"; then REF="$DEV"
elif [ "$HAS_COMMITS" = "yes" ]; then REF="HEAD"; fi

if [ -n "$REF" ]; then
  if [ -n "$LAST_TAG" ]; then
    RANGE="$LAST_TAG..$REF"
    LABEL="since $LAST_TAG up to $REF"
  else
    RANGE="$REF"
    LABEL="whole history of $REF (no tags yet)"
  fi
  N=$(git rev-list --count "$RANGE" 2>/dev/null || echo 0)
  echo "== Commits $LABEL =="
  echo "count: $N"
  if [ "$N" != "0" ]; then
    SUBJ=$(git log --no-merges --pretty=%s "$RANGE" 2>/dev/null)
    BODY=$(git log --no-merges --pretty=%b "$RANGE" 2>/dev/null)
    SUG="PATCH"
    if printf '%s\n' "$SUBJ" | grep -Eq '^[a-z]+(\([^)]*\))?!:' || printf '%s\n' "$BODY" | grep -q 'BREAKING CHANGE'; then
      SUG="MAJOR"
    elif printf '%s\n' "$SUBJ" | grep -Eq '^feat(\([^)]*\))?:'; then
      SUG="MINOR"
    fi
    NEXT=""
    if [ -n "$LAST_TAG" ]; then
      CORE=${LAST_TAG#v}; CORE=${CORE%%[-+]*}
      MA=${CORE%%.*}; REST=${CORE#*.}; MI=${REST%%.*}; PA=${REST#*.}
      case "$MA$MI$PA" in
        ''|*[!0-9]*) ;;
        *)
          case "$SUG" in
            MAJOR) NEXT="$((MA+1)).0.0" ;;
            MINOR) NEXT="$MA.$((MI+1)).0" ;;
            PATCH) NEXT="$MA.$MI.$((PA+1))" ;;
          esac ;;
      esac
    fi
    echo "bump suggestion:   $SUG${NEXT:+ -> $NEXT}  (Conventional Commits heuristic; the user decides)"
    echo "latest commits:"
    git log --no-merges --pretty='  - %s' "$RANGE" 2>/dev/null | head -n 10
  fi
  echo
fi

# ---------- pending items ----------
echo "== Pending items =="
PEND=0
if [ "$HAS_COMMITS" = "no" ]; then
  echo "- repository has no commits: an initial commit is needed before creating branches."
  PEND=1
fi
if [ "$HAS_COMMITS" = "yes" ] && ! has_local "$MAIN" && ! has_remote "$MAIN"; then
  echo "- branch '$MAIN' does not exist (current branch: $CUR_BRANCH): decide which one is production."
  PEND=1
fi
if ! has_local "$DEV" && ! has_remote "$DEV"; then
  echo "- branch '$DEV' does not exist: setup needed (references/setup.md)."
  PEND=1
elif ! has_local "$DEV" && has_remote "$DEV"; then
  echo "- '$DEV' exists only on the remote: create the local tracking branch."
  PEND=1
fi
if [ -z "$LAST_TAG" ] && [ "$HAS_COMMITS" = "yes" ]; then
  echo "- no version tag: consider a base tag (references/setup.md)."
  PEND=1
fi
if [ ! -f .gitflow ]; then
  echo "- no .gitflow file: conventions are being autodetected (optional: create one for the team)."
fi
if has_local "$MAIN" && has_local "$DEV"; then
  BEHIND=$(git rev-list --count "$DEV..$MAIN" 2>/dev/null || echo 0)
  if [ "$BEHIND" != "0" ]; then
    echo "- '$MAIN' has $BEHIND commit(s) that '$DEV' does not (hotfix/release without back-merge?)."
    PEND=1
  fi
fi
if [ -z "$REMOTE_URL" ]; then
  echo "- no 'origin' remote: push/PR/GitHub Release unavailable until one is configured."
fi
[ "$PEND" = "0" ] && echo "no structural pending items."
exit 0
