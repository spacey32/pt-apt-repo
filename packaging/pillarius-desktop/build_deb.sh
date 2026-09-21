#!/usr/bin/env bash
# Build the pillarius-desktop metapackage .deb.
#
# The metapackage contains no binaries: it exists so the whole Pillarius
# desktop environment can be installed with one command.  It depends on
# the core components and recommends the optional applications.
#
# Usage: ./build_deb.sh
set -euo pipefail

cd "$(dirname "$0")"

VER="1.1.0"
REL="1"
PKG="pillarius-desktop_${VER}-${REL}_all"
STAGE="build/${PKG}"
REPO_ROOT="$(cd ../.. && pwd)"
OUT="${REPO_ROOT}/pillarius-desktop_${VER}-${REL}_all.deb"

DOC_DIR="usr/share/doc/pillarius-desktop"

rm -rf "$STAGE"
mkdir -p "$STAGE/DEBIAN"
mkdir -p "$STAGE/$DOC_DIR"
mkdir -p "$STAGE/usr/share/pillarius-desktop"

# --- payload: documentation + a marker file ------------------------------
cat > "$STAGE/$DOC_DIR/README" <<'EOF'
Pillarius desktop environment
=============================

This metapackage installs the Pillarius X11 desktop environment:

  pillarium              lightweight X11 window manager (the desktop shell)
  spacer-greeter         LightDM greeter
  cadet                  companion toolkit / applications
  rocky                  office suite (RockyWrite, RockySheet, RockyPresent)

Optional applications (recommended, installed automatically unless
APT::Install-Recommends is disabled):

  planet                 graphical package manager
  planet-control-center  settings application

The window manager is started by LightDM via the "pillarium" session
(/usr/share/xsessions/pillarium.desktop).  The greeter is selected with
greeter-session=spacer-greeter in /etc/lightdm/lightdm.conf.d/.

Configuration for the window manager lives in ~/.pillarium/config.json and
can be edited with Planet Control Center or by hand.
EOF

printf 'pillarius-desktop %s-%s\n' "$VER" "$REL" \
    > "$STAGE/usr/share/pillarius-desktop/version"

cp debian/copyright "$STAGE/$DOC_DIR/copyright"
cp debian/changelog "$STAGE/$DOC_DIR/changelog.Debian"
gzip -9 -n -f "$STAGE/$DOC_DIR/changelog.Debian"

# --- permissions ---------------------------------------------------------
find "$STAGE" -type d -exec chmod 755 {} +
find "$STAGE" -type f -exec chmod 644 {} +

# --- control -------------------------------------------------------------
cat > "$STAGE/DEBIAN/control" <<EOF
Package: pillarius-desktop
Version: ${VER}-${REL}
Section: metapackages
Priority: optional
Architecture: all
Maintainer: Pillarium Developers <pillarium@users.noreply.github.com>
Installed-Size: 20
Depends: pillarium (>= 1.0.0), spacer-greeter (>= 1.0.0), cadet (>= 0.1.0), rocky (>= 0.1.0)
Recommends: planet (>= 0.1.0), planet-control-center (>= 0.1.0)
Description: Pillarius desktop environment (metapackage)
 Pillarius is a lightweight X11 desktop environment assembled from
 Pillarium (the window manager on which it is built), Spacer (the LightDM
 greeter) and Cadet (the companion toolkit/applications).
 .
 This metapackage pulls in the complete core Pillarius desktop in one
 step:
 .
   sudo apt install pillarius-desktop
 .
 Rocky, the office suite (RockyWrite, RockyWrite+, RockyGraphite,
 RockyGraphite+, RockySheet and RockyPresent), is included as part of the
 core desktop.
 .
 The optional desktop applications -- Planet (package manager) and Planet
 Control Center (settings) -- are pulled in as recommendations.
EOF

# --- build ---------------------------------------------------------------
mkdir -p "$REPO_ROOT"
dpkg-deb --build --root-owner-group "$STAGE" "$OUT"
rm -rf "$STAGE"
echo "Built: $OUT"
