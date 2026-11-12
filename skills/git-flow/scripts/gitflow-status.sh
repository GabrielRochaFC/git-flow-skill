#!/usr/bin/env bash
# gitflow-status.sh — diagnóstico SOMENTE LEITURA para a skill git-flow.
# Não altera nada no repositório. Uso: bash scripts/gitflow-status.sh
set -u

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "REPO: nenhum repositório git encontrado aqui."
  echo "AÇÃO: ver references/setup.md (seção 'Sem repositório')."
  exit 0
fi

cd "$(git rev-parse --show-toplevel)" || exit 1
ROOT=$(pwd)

# ---------- helpers ----------
has_local()  { git show-ref --verify --quiet "refs/heads/$1"; }
has_remote() { git show-ref --verify --quiet "refs/remotes/origin/$1"; }
mark()       { if "$1" "$2"; then echo "sim"; else echo "não"; fi; }

# cfg KEY DEFAULT  -> valor do .gitflow (aceita vazio explícito) ou DEFAULT
cfg() {
  if [ -f .gitflow ] && grep -Eq "^[[:space:]]*$1[[:space:]]*=" .gitflow; then
    grep -E "^[[:space:]]*$1[[:space:]]*=" .gitflow | tail -n1 \
      | sed -E 's/^[^=]*=//; s/[[:space:]]*#.*$//; s/^[[:space:]]+//; s/[[:space:]]+$//'
  else
    echo "$2"
  fi
}

CFG_SRC="autodetectado"
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

# ---------- configuração ----------
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

# ---------- relatório ----------
CUR_BRANCH=$(git symbolic-ref --short -q HEAD || echo "(HEAD destacado)")
DIRTY_COUNT=$(git status --porcelain | wc -l | tr -d ' ')
REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)
HAS_COMMITS="sim"
git rev-parse --verify -q HEAD >/dev/null 2>&1 || HAS_COMMITS="não"

echo "== Git Flow: diagnóstico =="
echo "repositório:       $ROOT"
echo "branch atual:      $CUR_BRANCH"
if [ "$DIRTY_COUNT" = "0" ]; then
  echo "working tree:      limpa"
else
  echo "working tree:      SUJA ($DIRTY_COUNT arquivo(s) alterado(s)) -> resolver antes de mergear"
fi
echo "commits no repo:   $HAS_COMMITS"
echo "remote origin:     ${REMOTE_URL:-ausente}"
echo

echo "== Convenções (origem: $CFG_SRC) =="
echo "branch de produção:  $MAIN"
echo "branch de integração: $DEV"
echo "prefixo da tag:      '${PREFIX}' (ex.: ${PREFIX}1.2.0)"
echo "arquivo de versão:   ${VFILE:-nenhum (versão só na tag)}"
echo "feature -> develop:  $FEATURE_MERGE"
echo "CHANGELOG.md:        $CHANGELOG"
echo "GitHub Release:      $GH_RELEASE"
echo

echo "== Branches =="
printf "%-22s local: %-4s remoto: %s\n" "$MAIN" "$(mark has_local "$MAIN")" "$(mark has_remote "$MAIN")"
printf "%-22s local: %-4s remoto: %s\n" "$DEV"  "$(mark has_local "$DEV")"  "$(mark has_remote "$DEV")"
OPEN=$(git for-each-ref --format='%(refname:short)' \
  refs/heads/release/ refs/heads/hotfix/ \
  refs/remotes/origin/release/ refs/remotes/origin/hotfix/ 2>/dev/null)
if [ -n "$OPEN" ]; then
  echo "releases/hotfixes abertos:"
  echo "$OPEN" | sed 's/^/  - /'
else
  echo "releases/hotfixes abertos: nenhum"
fi
FEATS=$(git for-each-ref --format='%(refname:short)' refs/heads/feature/ 2>/dev/null | wc -l | tr -d ' ')
echo "features locais:     $FEATS"
echo

echo "== Versão =="
echo "tags no repo:        $TAG_COUNT"
echo "última tag SemVer:   ${LAST_TAG:-nenhuma}"
echo "versão no arquivo:   ${FILE_VERSION:-n/a}"
if [ -n "$LAST_TAG" ] && [ "$DEFAULT_PREFIX" != "$PREFIX" ]; then
  echo "ALERTA: as tags existentes usam prefixo '${DEFAULT_PREFIX}' mas a configuração usa '${PREFIX}'. Alinhar com o time antes de criar novas tags."
fi
if [ -n "$LAST_TAG" ] && [ -n "$FILE_VERSION" ]; then
  TAG_CORE=${LAST_TAG#v}
  if [ "$TAG_CORE" != "$FILE_VERSION" ]; then
    echo "ALERTA: tag ($TAG_CORE) != versão do arquivo ($FILE_VERSION). Em develop o esperado é igualar a última release; pode haver release incompleta."
  fi
fi
echo

# ---------- commits desde a última tag + sugestão ----------
REF=""
if has_local "$DEV"; then REF="$DEV"
elif [ "$HAS_COMMITS" = "sim" ]; then REF="HEAD"; fi

if [ -n "$REF" ]; then
  if [ -n "$LAST_TAG" ]; then
    RANGE="$LAST_TAG..$REF"
    LABEL="desde $LAST_TAG até $REF"
  else
    RANGE="$REF"
    LABEL="histórico inteiro de $REF (sem tags ainda)"
  fi
  N=$(git rev-list --count "$RANGE" 2>/dev/null || echo 0)
  echo "== Commits $LABEL =="
  echo "quantidade: $N"
  if [ "$N" != "0" ]; then
    SUBJ=$(git log --no-merges --pretty=%s "$RANGE" 2>/dev/null)
    BODY=$(git log --no-merges --pretty=%b "$RANGE" 2>/dev/null)
    SUG="PATCH"
    if printf '%s\n' "$SUBJ" | grep -Eq '^[a-z]+(\([^)]*\))?!:' || printf '%s\n' "$BODY" | grep -q 'BREAKING CHANGE'; then
      SUG="MAIOR"
    elif printf '%s\n' "$SUBJ" | grep -Eq '^feat(\([^)]*\))?:'; then
      SUG="MENOR"
    fi
    NEXT=""
    if [ -n "$LAST_TAG" ]; then
      CORE=${LAST_TAG#v}; CORE=${CORE%%[-+]*}
      MA=${CORE%%.*}; REST=${CORE#*.}; MI=${REST%%.*}; PA=${REST#*.}
      case "$MA$MI$PA" in
        ''|*[!0-9]*) ;;
        *)
          case "$SUG" in
            MAIOR) NEXT="$((MA+1)).0.0" ;;
            MENOR) NEXT="$MA.$((MI+1)).0" ;;
            PATCH) NEXT="$MA.$MI.$((PA+1))" ;;
          esac ;;
      esac
    fi
    echo "sugestão de bump:  $SUG${NEXT:+ -> $NEXT}  (heurística por Conventional Commits; o usuário decide)"
    echo "últimos commits:"
    git log --no-merges --pretty='  - %s' "$RANGE" 2>/dev/null | head -n 10
  fi
  echo
fi

# ---------- pendências ----------
echo "== Pendências =="
PEND=0
if [ "$HAS_COMMITS" = "não" ]; then
  echo "- repositório sem commits: precisa de um commit inicial antes de criar branches."
  PEND=1
fi
if [ "$HAS_COMMITS" = "sim" ] && ! has_local "$MAIN" && ! has_remote "$MAIN"; then
  echo "- branch '$MAIN' não existe (branch atual: $CUR_BRANCH): decidir qual será a de produção."
  PEND=1
fi
if ! has_local "$DEV" && ! has_remote "$DEV"; then
  echo "- branch '$DEV' não existe: setup necessário (references/setup.md)."
  PEND=1
elif ! has_local "$DEV" && has_remote "$DEV"; then
  echo "- '$DEV' existe só no remoto: criar a branch local de rastreio."
  PEND=1
fi
if [ -z "$LAST_TAG" ] && [ "$HAS_COMMITS" = "sim" ]; then
  echo "- nenhuma tag de versão: considerar uma tag base (references/setup.md)."
  PEND=1
fi
if [ ! -f .gitflow ]; then
  echo "- sem arquivo .gitflow: convenções estão sendo autodetectadas (opcional criar para o time)."
fi
if has_local "$MAIN" && has_local "$DEV"; then
  BEHIND=$(git rev-list --count "$DEV..$MAIN" 2>/dev/null || echo 0)
  if [ "$BEHIND" != "0" ]; then
    echo "- '$MAIN' tem $BEHIND commit(s) que '$DEV' não tem (hotfix/release sem back-merge?)."
    PEND=1
  fi
fi
if [ -z "$REMOTE_URL" ]; then
  echo "- sem remote 'origin': push/PR/GitHub Release indisponíveis até configurar."
fi
[ "$PEND" = "0" ] && echo "nenhuma pendência estrutural."
exit 0
