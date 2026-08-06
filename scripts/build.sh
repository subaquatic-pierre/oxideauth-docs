#!/usr/bin/env bash
set -euo pipefail

echo "Building static site..."
mkdocs build
echo "Done. Output → site/"
