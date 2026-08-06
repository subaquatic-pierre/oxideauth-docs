# OxideAuth API

**Identity & Access Management Platform**

OxideAuth is a multi-tenant IAM (Identity & Access Management) REST API built in Rust. It provides authentication, role-based access control (RBAC), workspace management, and credential lifecycle management.

## Key Features

- **Multi-Tenancy** — Workspaces isolate users, projects, and permissions
- **RBAC** — Fine-grained role and permission system with wildcard support (`account:*`, `*:read`)
- **JWT Authentication** — HS256-signed tokens with blacklisting and refresh support
- **OAuth2 / OIDC** — Google OAuth integration for social login
- **Credential Management** — Password, OAuth, SSO, and API key credential types
- **Token Revocation** — Blacklist tokens by SHA-256 hash with expiry tracking
- **Email** — AWS SES integration with Tera HTML templates

## Architecture Overview

```mermaid
graph TD
    Client[API Client] -->|POST JSON + Bearer Token| Axum[Axum HTTP Server]
    Axum --> Auth[CtxMiddleware]
    Auth -->|Resolves JWT → CoreCtx| Handlers[Route Handlers]
    Handlers --> Services[Service Layer]
    Services -->|Permission Check| Perms[PermissionChecker]  
    Services --> Store[Data Access Layer]
    Store --> PG[(PostgreSQL)]
    Services --> Cache[(Redis)]
```

## API at a Glance

| Resource | Endpoints | Description |
|----------|-----------|-------------|
| [Health](api/health.md) | 2 | Server liveness & root endpoint |
| [Workspaces](api/workspace.md) | 5 | Multi-tenant containers |
| [Accounts](api/accounts.md) | 5 | User identity management |
| [Projects](api/projects.md) | 5 | Scoped work areas within workspaces |
| [Roles](api/roles.md) | 5 | Permission bundles |
| [Permissions](api/permissions.md) | 5 | Fine-grained access control |
| [Memberships](api/memberships.md) | 5 | Account-to-workspace/project links |
| [Credentials](api/credentials.md) | 4 | Auth credential lifecycle |
| [Tokens](api/tokens.md) | 3 | Blacklisted token management |

**39 total endpoints** — all JSON POST (except 2 GET health endpoints) with a standard `{ success, status, data }` envelope.

## Data Model

```mermaid
erDiagram
    Workspace ||--o{ Project : contains
    Workspace ||--o{ Membership : has
    Workspace ||--o{ Role : defines
    Workspace ||--o{ Permission : defines
    Account ||--o{ Membership : belongs_to
    Account ||--o{ Credential : authenticates_with
    Membership }o--|| Project : scoped_to
    Membership }o--o{ Role : assigned
    Role }o--o{ Permission : bundles
    Account ||--o{ Token : has_revoked
```

## Quick Links

- [Getting Started](getting-started.md) — Setup and first API call
- [Authentication](authentication.md) — Tokens, permissions, and security
- [Response Envelope](response-envelope.md) — Standard response format
- [Concepts](concepts/workspaces.md) — Deep dive into architecture concepts
- [Postman Collection](https://github.com/oxideauth/oxideauth/blob/main/references/OxideAuth.postman_collection.json) — Import-ready test collection
