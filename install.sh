#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${SYSGIT_REPO_URL:-https://framagit.org/kepon/sysgit.git}"
BRANCH="${SYSGIT_BRANCH:-main}"
PREFIX="${PREFIX:-/usr/local}"
SYSCONFDIR="${SYSCONFDIR:-/etc}"
DESTDIR="${DESTDIR:-}"
INSTALL_AUTOCOMMIT_TIMER="${SYSGIT_INSTALL_AUTOCOMMIT_TIMER:-1}"

have_cmd() { command -v "$1" >/dev/null 2>&1; }

fail() {
  echo "sysgit installer: $*" >&2
  exit 1
}

suggest_make_install() {
  if [ -r /etc/os-release ]; then
    . /etc/os-release
    case "${ID:-}${ID_LIKE:-}" in
      *debian*|*ubuntu*|*linuxmint*) echo "Try: sudo apt-get update && sudo apt-get install -y make git curl"; return;;
      *rhel*|*centos*|*fedora*|*rocky*|*alma*|*amzn*) echo "Try: sudo dnf install -y make git curl || sudo yum install -y make git curl"; return;;
      *suse*|*opensuse*) echo "Try: sudo zypper install -y make git curl"; return;;
      *alpine*) echo "Try: sudo apk add make git curl"; return;;
      *arch*|*manjaro*) echo "Try: sudo pacman -Sy --noconfirm make git curl"; return;;
    esac
  fi
  echo "Install the 'make' tool plus git/curl before continuing."
}

ensure_tools() {
  have_cmd make || { suggest_make_install; fail "missing required tool: make"; }
  if ! have_cmd git && ! have_cmd curl && ! have_cmd wget; then
    fail "need git or curl/wget to download the sources"
  fi
  have_cmd tar || fail "missing required tool: tar"
}

ensure_privileges() {
  if [ -n "${DESTDIR}" ]; then
    return
  fi
  if [ "$(id -u)" -ne 0 ] && { [ "${PREFIX}" = "/usr/local" ] || [ "${SYSCONFDIR}" = "/etc" ]; }; then
    fail "run with sudo (or set PREFIX/SYSCONFDIR/DESTDIR to writable locations)"
  fi
}

fetch_sources() {
  workdir="$(mktemp -d /tmp/sysgit-install.XXXXXX)"
  if have_cmd git; then
    git clone --depth 1 --branch "${BRANCH}" "${REPO_URL}" "${workdir}" >/dev/null
    echo "${workdir}"
    return
  fi

  archive_url="https://framagit.org/kepon/sysgit/-/archive/${BRANCH}/sysgit-${BRANCH}.tar.gz"
  downloader=()
  if have_cmd curl; then
    downloader=(curl -fsSL "${archive_url}")
  elif have_cmd wget; then
    downloader=(wget -qO- "${archive_url}")
  fi
  [ "${#downloader[@]}" -gt 0 ] || fail "no downloader available (git/curl/wget missing)"
  (umask 022 && "${downloader[@]}" | tar -xz -C "${workdir}" --strip-components=1) || fail "cannot download/extract sources"
  echo "${workdir}"
}

install_sysgit() {
  srcdir="$1"
  make_args=(install PREFIX="${PREFIX}" SYSCONFDIR="${SYSCONFDIR}" INSTALL_AUTOCOMMIT_TIMER="${INSTALL_AUTOCOMMIT_TIMER}")
  if [ -n "${DESTDIR}" ]; then
    make_args+=("DESTDIR=${DESTDIR}")
  fi
  (cd "${srcdir}" && make "${make_args[@]}")
}

ensure_tools
ensure_privileges
srcdir="$(fetch_sources)"
trap 'rm -rf "${srcdir}"' EXIT
install_sysgit "${srcdir}"
echo "sysgit installed (PREFIX=${PREFIX}, SYSCONFDIR=${SYSCONFDIR})"
if have_cmd systemctl && [ -z "${DESTDIR}" ]; then
  systemctl daemon-reload >/dev/null 2>&1 || true
  if [ "${INSTALL_AUTOCOMMIT_TIMER}" != "0" ]; then
    echo "Optional: enable the autocommit timer with: systemctl enable --now sysgit-autocommit.timer"
  else
    echo "Autocommit timer unit not installed (set SYSGIT_INSTALL_AUTOCOMMIT_TIMER=1 to include it)."
  fi
fi
if [ -z "${DESTDIR}" ]; then
  echo "Try: sysgit -h"
  echo "And after init with : sysgit init"
else
  echo "Files staged under DESTDIR=${DESTDIR}"
fi
