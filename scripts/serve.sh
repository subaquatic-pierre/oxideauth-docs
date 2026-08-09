#!/usr/bin/env bash
set -euo pipefail

echo "Starting MkDocs dev server..."
echo "Docs available at http://localhost:7000"
mkdocs serve --dev-addr=0.0.0.0:7000
