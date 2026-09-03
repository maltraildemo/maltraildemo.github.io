#!/bin/sh
# Rebuild this static demo from a Maltrail checkout.
#
# The demo is the SHIPPED dashboard with two differences: js/demo.js is present (main.js turns
# DEMO on from `typeof window.getDemoCSV === "function"`, so its mere presence is the switch), and
# the four placeholders the server normally fills in are substituted here instead.
#
#   ./build.sh [path-to-maltrail]      (default: ../maltrail)
#
# Regenerate the demo DATA first, in the Maltrail checkout, if the detections have changed:
#   python3 server.py --detect-test --keep /tmp/mt-demo
#   python3 sensor/tools/gen_demo_js.py --from /tmp/mt-demo/logs

set -eu
SRC="${1:-../maltrail}/html"
[ -d "$SRC" ] || { echo "[!] no html/ in ${1:-../maltrail} - pass the path to a Maltrail checkout"; exit 1; }

echo "[i] source: $SRC"

# Everything served is regenerated, so stale v1 assets cannot linger.
rm -rf css js images index.html favicon.ico robots.txt
mkdir -p css js images

cp "$SRC/index.html"            index.html
cp "$SRC/css/main.css"          css/
cp "$SRC/js/main.js"            js/
cp "$SRC/js/thirdparty.min.js"  js/
cp "$SRC/js/worldmap.js"        js/
cp "$SRC/js/demo.js"            js/
cp "$SRC/images/mlogo.png"      images/
cp "$SRC/favicon.ico"           favicon.ico
# NOT robots.txt. Maltrail ships "Disallow: /" because a real deployment's dashboard is private
# and should never be indexed - correct there, wrong here: this site exists to be found. Removing
# the file (rather than shipping a permissive one) lets crawlers index by default.
# NOT copied: images/logo.xcf (GIMP source), README.txt (developer note)

# The server fills these in per request; a static host does not. Left alone they are parsed as
# bogus comments and silently dropped, which is how the v1 demo ended up rendering "(v)".
VER=$(sed -n 's/^VERSION *= *"\([^"]*\)".*/\1/p' "${1:-../maltrail}/core/settings.py" | head -1)
ASSETVER=$(date -u +%s)
sed -i \
  -e "s|<!VERSION!>|${VER}|g" \
  -e "s|<!ASSETVER!>|${ASSETVER}|g" \
  -e "s|<!TZOFFSET!>|0|g" \
  -e 's|<!LOGO!>|<img src="images/mlogo.png" style="width: 25px">altrail|g' \
  index.html

if grep -q '<![A-Z_]*!>' index.html; then
    echo "[!] unsubstituted placeholder left in index.html:"
    grep -o '<![A-Z_]*!>' index.html | sort -u | sed 's/^/[!]     /'
    exit 1
fi

echo "[i] built: version ${VER}, assetver ${ASSETVER}"
du -sh . | sed 's/^/[i] size: /'
