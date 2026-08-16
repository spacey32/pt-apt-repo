#!/usr/bin/env bash
# Publish .deb packages into the apt repository and refresh signed indexes.
#
# Usage:  ./publish.sh [path/to/pkg1.deb] [path/to/pkg2.deb] ...
#
# Each .deb is copied into the pool (pool/main/<letter>/<name>/), then the
# Packages indexes and the signed Release files are regenerated.
set -euo pipefail

cd "$(dirname "$0")"

REPO="$PWD/repo"
DIST="$REPO/dists/stable"
MAIN="$DIST/main"
ARCHES=(all amd64)

if [ "$#" -eq 0 ]; then
    echo "usage: $0 <pkg.deb> [...]" >&2
    exit 2
fi

# --- 1. stage the .debs into the pool ------------------------------------
for deb in "$@"; do
    [ -f "$deb" ] || { echo "error: not a file: $deb" >&2; exit 1; }

    name=$(dpkg-deb -f "$deb" Package)
    ver=$(dpkg-deb -f "$deb" Version)
    arch=$(dpkg-deb -f "$deb" Architecture)
    letter="${name:0:1}"

    # sanitize: pool paths may only contain [a-z0-9]
    letter=$(echo "$letter" | tr 'A-Z' 'a-z')
    name=$(echo "$name" | tr 'A-Z' 'a-z')
    dir="$REPO/pool/main/$letter/$name"
    dest="$dir/${name}_${ver}_${arch}.deb"

    mkdir -p "$dir"
    if [ -e "$dest" ] && ! cmp -s "$deb" "$dest"; then
        echo "error: $dest already exists with different content" >&2
        exit 1
    fi
    cp -f "$deb" "$dest"
    echo "staged: $dest"
done

# --- 2. regenerate the package indexes ------------------------------------
cd "$REPO"
for a in "${ARCHES[@]}"; do
    apt-ftparchive packages pool > "dists/stable/main/binary-$a/Packages"
    gzip -9 -c -n "dists/stable/main/binary-$a/Packages" \
        > "dists/stable/main/binary-$a/Packages.gz"
    echo "index: binary-$a/Packages"
done

# --- 3. regenerate Release and sign it ------------------------------------
apt-ftparchive -c "$DIST/ftparchive.conf" release "$DIST" > "$DIST/Release"
GNUPGHOME="$REPO/.gnupg" gpg --batch --yes -abs \
    -o "$DIST/Release.gpg" "$DIST/Release"
GNUPGHOME="$REPO/.gnupg" gpg --batch --yes -abs --clearsign \
    -o "$DIST/InRelease" "$DIST/Release"
echo "signed: Release.gpg, InRelease"

# --- 4. sanity check: InRelease must verify against the published key ------
# Guards against shipping a repo signed with a key users don't have (NO_PUBKEY).
CHECK=$(mktemp -d)
trap 'rm -rf "$CHECK"' EXIT
gpg --homedir "$CHECK" --import "$DIST/pillarium-repo.gpg.key" >/dev/null 2>&1
if ! gpg --homedir "$CHECK" --verify "$DIST/InRelease" >/dev/null 2>&1; then
    echo "error: InRelease does not verify against $DIST/pillarium-repo.gpg.key" >&2
    echo "hint: re-export the current public key: gpg --export <keyid> > $DIST/pillarium-repo.gpg.key" >&2
    exit 1
fi
echo "verified: InRelease matches published key"
echo "done. commit the repo and push to publish (GitHub Pages)."