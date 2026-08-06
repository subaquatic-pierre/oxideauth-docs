.PHONY: install serve build clean dev

# Default target
.DEFAULT_GOAL := serve

# Install Python dependencies
install:
	pip install -r requirements.txt

# Start live-reload dev server
serve:
	mkdocs serve --dev-addr=0.0.0.0:8000

# Build static site
build:
	mkdocs build

# Clean build output
clean:
	rm -rf site/

# Install deps and start dev server
dev: install serve
