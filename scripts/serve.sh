#!/usr/bin/env bash
set -euo pipefail

echo "Starting MkDocs dev server..."
echo "Docs available at http://localhost:8000"
mkdocs serve --dev-addr=0.0.0.0:8000
