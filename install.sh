#!/usr/bin/env bash
# Add the Pillarium apt repository to this machine and refresh indexes.
#
# Usage:  curl -fsSL https://spacey32.github.io/pt-apt-repo/install.sh | sudo bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "error: run as root (sudo)" >&2
    exit 1
fi

BASE="${PILLARIUM_REPO_URL:-https://spacey32.github.io/pt-apt-repo}"
KEYRING=/usr/share/keyrings/pillarium-repo.gpg
LIST=/etc/apt/sources.list.d/pillarium.list
EXPECTED_FPR=7F41A7288611ABAAEBBA94008E9C74FF94707AF0

tmp=$(mktemp)
bin=$(mktemp)
trap 'rm -f "$tmp" "$bin"' EXIT

echo "fetching key from $BASE/dists/stable/pillarium-repo.gpg.key"
curl -fsSL "$BASE/dists/stable/pillarium-repo.gpg.key" -o "$tmp"
gpg --dearmor < "$tmp" > "$bin"

fpr=$(gpg --show-keys --with-colons "$bin" 2>/dev/null | awk -F: '$1=="fpr"{print $10; exit}')
if [ "$fpr" != "$EXPECTED_FPR" ]; then
    echo "error: unexpected key fingerprint $fpr (expected $EXPECTED_FPR)" >&2
    exit 1
fi

if ! cmp -s "$bin" "$KEYRING"; then
    install -m 0644 "$bin" "$KEYRING"
    echo "installed keyring: $KEYRING"
fi

echo "deb [signed-by=$KEYRING] $BASE stable main" > "$LIST"
echo "wrote: $LIST"

apt-get update