.PHONY: help install serve build clean dev deploy

.DEFAULT_GOAL := help

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-12s\033[0m %s\n", $$1, $$2}'

install: ## Install Python dependencies
	pip install -r requirements.txt

serve: ## Start live-reload dev server
	mkdocs serve --dev-addr=0.0.0.0:7000

build: ## Build static site
	mkdocs build

clean: ## Clean build output
	rm -rf site/

dev: install serve

deploy: ## Build and deploy the site
	bash scripts/deploy.sh $(filter-out $@,$(MAKECMDGOALS))

%:
	@:
