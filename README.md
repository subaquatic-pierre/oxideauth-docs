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
# Docs available at http://localhost:8001
```

The docs service hot-reloads on every file change — just edit markdown and refresh your browser.

### Option 2: Standalone (from this directory)

```sh
# Install dependencies
make install

# Start live-reload dev server
make serve
# Docs available at http://localhost:8000

# Build static site
make build
# Output → site/
```

Or with the scripts directly:

```sh
./scripts/install.sh
./scripts/serve.sh      # live-reload at http://localhost:8000
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
