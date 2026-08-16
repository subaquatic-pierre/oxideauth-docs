# Getting Started

This guide walks you through setting up and making your first OxideAuth API call.

## Prerequisites

- **OxideAuth server** running (see project README for build/run instructions)
- **PostgreSQL 16** with the OxideAuth schema applied
- **Redis 7** for caching and token revocation
- A tool for making HTTP requests (cURL, Postman, or any HTTP client)

## Base URL

All API requests are made to the server's base URL:

```
http://127.0.0.1:8000
```

The port defaults to `8000` (configurable via `PORT` environment variable). The Docker image exposes port `8000`.

## Import the Postman Collection

We provide a ready-to-use Postman collection with all 62 endpoints, example payloads, and auto-populated variables:

1. Download the [Postman collection](https://github.com/subaquatic-pierre/oxideauth/blob/main/references/OxideAuth.postman_collection.json) from the repository
2. In Postman, click **Import** → select the downloaded file
3. Set the `host` collection variable to your API's base URL
4. Set the `token` variable to a valid Bearer JWT

## Your First Request

### 1. Check the Server is Running

```bash
curl -s http://127.0.0.1:8000/health-check | jq
```

```json title="Response"
{
  "success": true,
  "status": 200,
  "data": "Healthy"
}
```

### 2. Create a Workspace

Workspaces are the top-level organizational units. All other resources belong to a workspace.

```bash
curl -s -X POST http://127.0.0.1:8000/workspace/create \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "name": "My Organization",
    "slug": "my-org",
    "description": "Primary workspace",
    "config": { "schema_version": "1.0" },
    "tags": ["production"],
    "meta": { "schema_version": "1.0" }
  }' | jq
```

```json title="Response"
{
  "success": true,
  "status": 200,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "My Organization",
    "slug": "my-org",
    "description": "Primary workspace",
    "config": { "schema_version": "1.0" },
    "tags": ["production"],
    "meta": { "schema_version": "1.0" },
    "created_at": "2026-08-06T12:00:00Z",
    "updated_at": null
  }
}
```

### 3. Create an Account

```bash
curl -s -X POST http://127.0.0.1:8000/accounts/create \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "email": "alice@example.com",
    "password": "SecureP@ssw0rd!",
    "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Alice Johnson",
    "description": "Engineering team lead",
    "avatar_url": null,
    "tags": ["engineering"],
    "meta": { "schema_version": "1.0" }
  }' | jq
```

## Request Conventions

### HTTP Method

Almost all endpoints use **POST** with a JSON body — even read operations. Only `GET /`, `GET /health-check`, and `GET /auth/oauth/google/callback` use GET.

### Content-Type

All request bodies must use `Content-Type: application/json`.

### Empty Request Body

List endpoints (`/accounts/list`, `/projects/list`, `/clients/list`, etc.) accept an empty body `{}` — this applies no filters and uses default list options (limit=100, newest first). Create, update, and delete endpoints require their mandatory fields and will return validation errors when sent an empty body.

!!! warning
    An empty body `{}` is valid **only** for list endpoints. Non-list endpoints (create, describe, update, delete, and auth operations with required fields) will reject it with a validation error.

### Authentication

All resource management endpoints require a Bearer token. The health endpoints (`GET /`, `GET /health-check`) and the public Auth endpoints (Register, Login, Password Reset, Account Confirmation, OAuth2) do **not** require authentication:

```
Authorization: Bearer <JWT_TOKEN>
```

See [Auth API](api/auth.md) for login/registration endpoints and [Authentication](authentication.md) for details on obtaining and managing tokens.

### Response Format

Every response follows a standard envelope:

```json
{
  "success": true,
  "status": 200,
  "data": { ... }
}
```

See [Response Envelope](response-envelope.md) for the complete specification.

## Recommended Workflow

Follow this order when setting up a new workspace:

1. **[Workspace](api/workspace.md#create-workspace)** — Create the tenant
2. **[Permissions](api/permissions.md#create-permission)** — Define fine-grained permissions
3. **[Roles](api/roles.md#create-role)** — Bundle permissions into roles
4. **[Accounts](api/accounts.md#create-account)** — Create user accounts
5. **[Memberships](api/memberships.md#create-membership)** — Link accounts to the workspace with roles
6. **[Projects](api/projects.md#create-project)** — Create scoped work areas (optional)

## Next Steps

- [Authentication Guide](authentication.md) — Understand JWT tokens and permission checking
- [Concepts](concepts/workspaces.md) — Deep dive into multi-tenancy and RBAC
- [API Reference](api/workspace.md) — Complete endpoint documentation
