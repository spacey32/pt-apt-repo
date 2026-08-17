#!/usr/bin/env bash
# Regenerate repo/index.html listing every .deb in the pool.
set -euo pipefail

cd "$(dirname "$0")"

REPO="$PWD/repo"
OUT="$REPO/index.html"
BASE="https://spacey32.github.io/pt-apt-repo"

BODY=""
while IFS= read -r deb; do
    [ -n "$deb" ] || continue
    name=$(dpkg-deb -f "$deb" Package)
    ver=$(dpkg-deb -f "$deb" Version)
    arch=$(dpkg-deb -f "$deb" Architecture)
    desc=$(dpkg-deb -f "$deb" Description | head -1)
    size=$(stat -c %s "$deb")
    if [ "$size" -lt 1048576 ]; then
        size_str=$(awk "BEGIN{printf \"%.0f KB\", $size/1024}")
    else
        size_str=$(awk "BEGIN{printf \"%.1f MB\", $size/1048576}")
    fi
    url="$BASE/${deb#$REPO/}"
    BODY+=$"          <tr>"$'\n'
    BODY+=$"            <td class=\"name\">${name}</td>"$'\n'
    BODY+=$"            <td>${ver}</td>"$'\n'
    BODY+=$"            <td>${arch}</td>"$'\n'
    BODY+=$"            <td class=\"desc\">${desc}</td>"$'\n'
    BODY+=$"            <td>${size_str}</td>"$'\n'
    BODY+=$"            <td><a class=\"asset\" href=\"${url}\">download</a></td>"$'\n'
    BODY+=$"          </tr>"$'\n'
done < <(find "$REPO/pool" -name "*.deb" | sort)

cat > "$OUT" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Pillarium Apt Repository</title>
<style>
  body { margin: 0; padding: 40px 20px; background: #1e1e2e; color: #cdd6f4;
         font-family: "DejaVu Sans", sans-serif; }
  main { max-width: 900px; margin: 0 auto; }
  h1 { color: #89b4fa; }
  pre { background: #181825; border: 1px solid #313244; border-radius: 8px;
        padding: 14px 18px; overflow-x: auto; color: #a6e3a1; font-size: 13px; }
  table { width: 100%; border-collapse: collapse; margin-top: 12px; }
  th, td { text-align: left; padding: 8px 10px; border-bottom: 1px solid #313244;
           font-size: 14px; }
  th { color: #89b4fa; }
  td.name { color: #f5c2e7; font-weight: bold; }
  td.desc { color: #6c7086; font-size: 12px; }
  a.asset { color: #89b4fa; text-decoration: none; }
  a.asset:hover { text-decoration: underline; }
  footer { margin-top: 40px; color: #6c7086; font-size: 12px; }
</style>
</head>
<body>
<main>
  <h1>Pillarium Apt Repository</h1>
  <p>Apt repository for Pillarium and the PillarTree desktop components
     (<strong>pillarium</strong>, <strong>spacer-greeter</strong>,
     <strong>cadet</strong>, <strong>planet</strong>), target: Debian trixie.</p>
  <h2>Install</h2>
  <pre>curl -fsSL ${BASE}/install.sh | sudo bash</pre>
  <h2>Packages</h2>
  <table>
    <tr><th>Package</th><th>Version</th><th>Arch</th><th>Description</th><th>Size</th><th></th></tr>
${BODY}  </table>
  <footer>Source: <a style="color:#89b4fa" href="https://github.com/spacey32/pt-apt-repo">spacey32/pt-apt-repo</a> &middot; Pillarius ISOs: <a style="color:#89b4fa" href="https://pillartree.github.io/Pillarius/">PillarTree/Pillarius</a></footer>
</main>
</body>
</html>
EOF

echo "wrote $OUT"