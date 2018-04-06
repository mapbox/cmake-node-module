#!/usr/bin/env sh

set -euo pipefail
function finish { rm -rf build ; }
trap finish EXIT
finish

npm install
node run.js
