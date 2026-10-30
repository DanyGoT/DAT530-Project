#!/usr/bin/env bash
# Render every net in this folder to SVG and PDF with Graphviz.
set -euo pipefail
cd "$(dirname "$0")"
nix shell nixpkgs#graphviz -c sh -c '
for f in *.dot; do
  dot -Tsvg "$f" -o "${f%.dot}.svg"
  dot -Tpdf "$f" -o "${f%.dot}.pdf"
done'
