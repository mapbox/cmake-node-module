#!/usr/bin/env sh

set -euo pipefail
function finish { rm -rf build lib ; }
trap finish EXIT
finish

npm install
node run.js
