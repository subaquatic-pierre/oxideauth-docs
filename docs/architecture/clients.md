# Clients Entity

The **Client** is a first-class entity in the OxideAuth IAM model that represents a registered external microservice integrated with the platform. Clients form the bridge between OxideAuth's centralized authorization and the distributed microservices that enforce it.

## Purpose

A Client in OxideAuth serves two primary roles:

1. **Token Validation**: Client microservices call the [Validate endpoint](../api/validate.md) to check whether an end user's access token grants sufficient permissions for a requested operation. This is the runtime authorization path — every user request to a microservice results in a validate call.

2. **Push-Based Cache Invalidation**: When authorization state changes in OxideAuth (token revocation, permission updates, role changes, membership changes), registered clients receive push notifications so they can invalidate their local authorization caches. This ensures authorization decisions remain consistent without requiring clients to poll for changes.

## Entity Model

### Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `id` | UUID | Unique client identifier |
| `workspace_id` | UUID | Owning workspace — clients are workspace-scoped |
| `name` | string | Human-readable name for the service |
| `secret_hash` | SHA-256 | Hashed client secret (write-only, never returned in API responses) |
| `endpoint` | string (URL) | The update endpoint URL on the client's side that OxideAuth calls to push cache invalidation events |
| `description` | string? | Optional description of the service |
| `tags` | string[] | Categorization tags |
| `meta` | object | Extensible metadata (requires `schema_version`) |
| `audit` | object | Audit trail with `created_at`, `created_by`, `updated_at`, `updated_by` |

### Secret Management

Each Client has a **secret** — a cryptographically generated string that authenticates the client when calling the Validate endpoint. The secret:

- Is returned in plaintext **only once** — on creation (`POST /clients/create`) or regeneration (`POST /clients/regenerate-secret`)
- Is stored as a SHA-256 hash in the database — the plaintext is never persisted
- Can be rotated via the regenerate-secret endpoint, which immediately invalidates the old secret
- Is required in `client_secret` field of every Validate request

!!! warning "Secret Security"
    The client secret is the credential that allows a microservice to validate tokens. Treat it like a password: store it securely (environment variables, secrets manager), never commit it to version control, and rotate it if compromised.

## Lifecycle

Clients follow a straightforward, operation-driven lifecycle. There is **no enable/disable toggle** — a client cannot be suspended; it is created, updated as needed, and eventually deleted:

```text
[Create] → [Update] → [Delete]
               │
        [Regenerate Secret]
```

### Operations

| Operation | Endpoint | Notes |
|-----------|----------|-------|
| **Create** | `POST /clients/create` | Registers a new client in a workspace. The plaintext secret is returned exactly once. |
| **Update** | `POST /clients/update` | Modifies `name`, `endpoint`, `description`, `tags`, and/or `meta`. All fields are optional. |
| **Regenerate Secret** | `POST /clients/regenerate-secret` | Rotates the client secret, immediately invalidating the old one. |
| **Delete** | `POST /clients/delete` | Permanently removes the client. This cannot be undone. |

- **Create**: A client becomes operational immediately upon creation. The returned secret must be stored securely, as it is shown only once.
- **Update**: Any mutable field (`name`, `endpoint`, `description`, `tags`, `meta`) can be changed at any time. There is no `enabled` field and no way to disable a client — it can only be updated or deleted.
- **Regenerate Secret**: If a secret is compromised, rotate it via the regenerate-secret endpoint. The new secret is returned once and the old secret is invalidated immediately.
- **Delete**: Permanently removes the client and its associated data. This is the only way to stop a client from operating.

## Relationship to Workspaces

Each Client belongs to exactly one **Workspace**. This scoping means:

- A client can only validate tokens for the workspace it belongs to
- A client only receives push updates for changes within its workspace
- Client secrets are scoped to one workspace — a compromised secret only affects one workspace
- The relationship is many-to-one: a workspace can have multiple clients (e.g., separate microservices for payments, notifications, and analytics)

## How Clients Differ from Accounts

| Aspect | Account | Client |
|--------|---------|--------|
| **What it represents** | A human user or service account identity | A registered external microservice |
| **Authentication** | Email/password or OAuth (user-focused) | Client secret (service-to-service) |
| **Token ownership** | Owns JWT access tokens (Bearer) | Validates tokens owned by Accounts |
| **Push notifications** | Not applicable | Receives push updates for cache invalidation |
| **Workspace scoping** | Can belong to multiple workspaces via memberships | Belongs to exactly one workspace |
| **Permissions** | Granted via roles and memberships | Uses its own permissions to manage itself (`client:create`, `client:delete`, etc.) |
| **Lifecycle management** | Create, enable/disable, verify email | Create, update, regenerate secret, delete |

## Permissions

The following permissions govern client management operations:

| Permission | Operation |
|------------|-----------|
| `client:create` | Register a new client in a workspace |
| `client:describe` | View a client's details (excluding secret) |
| `client:list` | List all clients in a workspace |
| `client:delete` | Remove a client from a workspace |
| `client:regenerateSecret` | Rotate a client's secret |

These permissions are granted to Accounts via roles and memberships, just like any other OxideAuth permission.

## Integration Pattern

A typical Client integration follows this flow:

1. An administrator creates a Client via the API (or dashboard), obtaining a `secret`
2. The secret is deployed alongside the microservice (environment variable, secrets manager)
3. The microservice exposes an update endpoint (the `endpoint` field on the Client) that accepts POST requests from OxideAuth
4. For each incoming user request, the microservice:
   - Extracts the user's Bearer token from the Authorization header
   - Calls `POST /clients/validate` with the client secret, user token, and required permissions
   - Proceeds or rejects based on the `authorized` response
5. When authorization state changes in OxideAuth, the microservice receives a push notification at its endpoint and invalidates relevant cache entries

See [Push Model](push-model.md) for details on implementing the push notification receiver.
