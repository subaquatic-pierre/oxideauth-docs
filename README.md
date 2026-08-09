# OxideAuth Documentation

Built with [MkDocs](https://www.mkdocs.org/) + [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/).

## Sections

| Section | Contents |
|---------|----------|
| **Home** | Architecture overview with Mermaid diagrams |
| **Getting Started** | Setup guide, first API calls, recommended workflow |
| **API Reference** | 39 endpoints across 9 resources — Health, Workspaces, Accounts, Projects, Roles, Permissions, Memberships, Credentials, Tokens |
| **Concepts** | Multi-tenancy & workspaces, RBAC & permissions, membership model |
| **Architecture** | Design docs — request flow, entities, auth flow, login, token architecture, service factory, store module, SQLx vs Diesel, embedded worker, and more |

## Quick Start

### Option 1: Docker Compose (from project root)

```sh
# Start all services including docs
docker compose up -d
# Docs available at http://localhost:7000
```

The docs service hot-reloads on every file change — just edit markdown and refresh your browser.

### Option 2: Standalone (from this directory)

```sh
# Install dependencies
make install

# Start live-reload dev server
make serve
# Docs available at http://localhost:7000

# Build static site
make build
# Output → site/
```

Or with the scripts directly:

```sh
./scripts/install.sh
./scripts/serve.sh      # live-reload at http://localhost:7000
./scripts/build.sh      # static site → site/
```

## Development Workflow

### Editing docs

1. Run the dev server: `make serve` (or `docker compose up -d` from project root)
2. Edit any `.md` file in `docs/` — the browser reloads automatically
3. Sidebar navigation is defined in `mkdocs.yml` under `nav:`

### Adding a new page

1. Create a `.md` file in the appropriate subdirectory under `docs/`
2. Add it to the `nav:` section in `mkdocs.yml`
3. If adding to **API Reference**, follow the existing endpoint doc format
4. If adding to **Architecture**, place it under `docs/architecture/`

### Building for production

```sh
make build
# Static site output → site/
```

The built site is git-ignored — it is regenerated in CI/CD or before deployment.

### Deploying to GitHub Pages

The docs site is deployed to GitHub Pages. Two deployment methods are available:

#### Option 1: Git Tag Push (CI Trigger)

```sh
# From the docs/ directory, create and push a semantic version tag:
git tag 1.0.0
git push origin 1.0.0
```

Pushing a tag matching `*.*.*` triggers the GitHub Actions workflow at `.github/workflows/deploy.yml`, which:
1. Checks out the repository
2. Sets up Python and installs dependencies
3. Builds the MkDocs site (`mkdocs build` → `site/`)
4. Deploys to GitHub Pages

#### Option 2: Manual Deploy via Script

```sh
make deploy patch    # bump patch version (0.0.0 → 0.0.1)
make deploy minor    # bump minor version (0.0.0 → 0.1.0)
make deploy major    # bump major version (0.0.0 → 1.0.0)
make deploy 1.2.3    # use explicit version
```

The `make deploy` command runs `scripts/deploy.sh`, which:
1. Bumps the version (from git tags)
2. Builds the MkDocs site (`mkdocs build` → `site/`)
3. Creates and pushes an `X.Y.Z` tag
4. Force-pushes build output to the `gh-pages` branch

All tags use semantic versioning (e.g., `1.2.3`). Deployments target the `main` branch.

### Directory structure

```
docs/
├── mkdocs.yml              # MkDocs configuration
├── requirements.txt        # Python dependencies
├── Makefile                # Dev commands
├── scripts/                # Shell helpers
│   ├── install.sh
│   ├── serve.sh
│   └── build.sh
├── Dockerfile              # Docker image for compose
├── docs/                   # All markdown source
│   ├── index.md
│   ├── getting-started.md
│   ├── authentication.md
│   ├── response-envelope.md
│   ├── api/                # API reference (9 resources)
│   ├── concepts/           # Concept deep-dives
│   └── architecture/       # Architecture & design docs
└── site/                   # Built output (gitignored)
```
