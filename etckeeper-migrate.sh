#!/bin/bash

set -euo pipefail

CONFIG=/etc/sysgit.conf
GIT=/usr/bin/git
SYSGIT_DIR=/var/lib/sysgit
ETCKEEPER_GIT=/etc/.git

usage() {
  cat <<'EOF'
Usage: etckeeper-migrate.sh [-c <config>]
  -c <config>  Chemin vers le fichier de configuration sysgit
  -h           Afficher cette aide
EOF
}

while getopts ":c:h" opt; do
  case "${opt}" in
    c)
      CONFIG="${OPTARG}"
      ;;
    h)
      usage
      exit 0
      ;;
    \?)
      echo "Option inconnue: -${OPTARG}" >&2
      usage >&2
      exit 2
      ;;
    :)
      echo "L'option -${OPTARG} requiert un argument." >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ -f "${CONFIG}" ]; then
  . "${CONFIG}"
fi

if [ -x "${GIT}" ]; then
  GIT_BIN="${GIT}"
elif command -v git >/dev/null 2>&1; then
  GIT_BIN="$(command -v git)"
else
  echo "git introuvable." >&2
  exit 1
fi

export PATH
PATH="$(dirname "${GIT_BIN}"):${PATH}"

git_cmd() {
  "${GIT_BIN}" "$@"
}

resolve_branch() {
  local git_dir="${1}"
  local branch=""
  branch="$(git_cmd --git-dir="${git_dir}" symbolic-ref --quiet HEAD 2>/dev/null || true)"
  if [ -n "${branch}" ]; then
    echo "${branch#refs/heads/}"
    return 0
  fi
  for candidate in main master; do
    if git_cmd --git-dir="${git_dir}" show-ref --verify --quiet "refs/heads/${candidate}"; then
      echo "${candidate}"
      return 0
    fi
  done
  return 1
}

if [ ! -d "${ETCKEEPER_GIT}" ]; then
  echo "Depot etckeeper introuvable: ${ETCKEEPER_GIT}" >&2
  exit 1
fi

if [ ! -d "${SYSGIT_DIR}" ]; then
  git_cmd init --bare "${SYSGIT_DIR}"
fi

sysgit_branch="$(resolve_branch "${SYSGIT_DIR}" || echo "master")"
etckeeper_branch="$(resolve_branch "${ETCKEEPER_GIT}")"
if [ -z "${etckeeper_branch}" ]; then
  echo "Impossible de determiner la branche etckeeper." >&2
  exit 1
fi

tmpdir="$(mktemp -d /var/tmp/sysgit-etckeeper.XXXXXX)"
cleanup() {
  rm -rf "${tmpdir}"
}
trap cleanup EXIT

echo "Clonage de ${ETCKEEPER_GIT}..."
git_cmd clone "${ETCKEEPER_GIT}" "${tmpdir}/etckeeper"

echo "Reecriture de l'historique avec le prefixe /etc..."
git_cmd -C "${tmpdir}/etckeeper" filter-branch --force --index-filter '
git ls-files -s | sed "s#\t#\tetc/#" | GIT_INDEX_FILE=$GIT_INDEX_FILE.new git update-index --index-info &&
mv "$GIT_INDEX_FILE.new" "$GIT_INDEX_FILE"
' -- --all

git_cmd -C "${tmpdir}/etckeeper" remote add sysgit "${SYSGIT_DIR}"
git_cmd -C "${tmpdir}/etckeeper" push -f sysgit \
  "refs/heads/${etckeeper_branch}:refs/heads/etckeeper-migrate"

if git_cmd --git-dir="${SYSGIT_DIR}" rev-parse --verify HEAD >/dev/null 2>&1; then
  echo "Fusion dans le depot sysgit (strategie ours)..."
  git_cmd --git-dir="${SYSGIT_DIR}" worktree add "${tmpdir}/sysgit-work" "${sysgit_branch}"
  git_cmd -C "${tmpdir}/sysgit-work" merge --allow-unrelated-histories -m \
    "Import etckeeper history" -s ours etckeeper-migrate
  git_cmd --git-dir="${SYSGIT_DIR}" worktree remove --force "${tmpdir}/sysgit-work"
else
  echo "Depot sysgit vide: initialisation depuis etckeeper."
  git_cmd --git-dir="${SYSGIT_DIR}" branch -f "${sysgit_branch}" etckeeper-migrate
fi

cat <<EOF
Migration terminee.

Conseils:
- Verifiez l'etat: sysgit status
- Synchronisez l'etat courant de /etc si besoin: sysgit add -A /etc && sysgit commit -m "Sync /etc"
- Desactivez etckeeper et supprimez /etc/.git si vous ne souhaitez plus l'utiliser.
EOF
