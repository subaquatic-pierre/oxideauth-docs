# Authentication

OxideAuth uses JWT Bearer tokens for authentication and a permission-based authorization system.

## Auth API Reference

All authentication endpoints (Register, Login, Refresh, Password Reset, Account Confirmation, Token Revocation, and OAuth2) are documented in the [Auth API](api/auth.md) reference.

---

## Token Format

Tokens are **HS256** (HMAC-SHA256) JWTs signed with the `JWT_SECRET` environment variable.

### Token Claims

| Claim | Type | Description |
|-------|------|-------------|
| `sub` | UUID | Account ID of the authenticated user |
| `ws` | UUID | Current workspace ID |
| `mem` | UUID | Membership ID for the current session |
| `iss` | string | Token issuer |
| `aud` | string | Token audience |
| `exp` | integer | Expiration timestamp (Unix epoch) |
| `iat` | integer | Issued-at timestamp (Unix epoch) |
| `ty` | string | Token type (see below) |

### Token Types

| Type | Description | Max Age |
|------|-------------|---------|
| `Auth` | Standard access token | 24 hours (configurable via `TOKEN_MAXAGE`) |
| `Refresh` | Token used to obtain a new Auth token | Extended lifetime |
| `PasswordReset` | Single-use token for password reset flows | Short-lived |
| `AccountConfirm` | Token for email verification | Extended lifetime |

## Passing Authentication

Include the token in the `Authorization` header of every request:

```http
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

!!! warning
    The two health endpoints (`GET /` and `GET /health-check`) do **not** require authentication. All other endpoints return `401 Unauthorized` if the token is missing, expired, or blacklisted.

## Permission System

### Resource:Action Format

Permissions use a `resource:action` naming convention with wildcard support:

| Pattern | Matches | Example |
|---------|---------|---------|
| `account:readAny` | Read any account | View user profiles |
| `account:updateSelf` | Update your own account | Edit profile |
| `workspace:*` | All workspace actions | Full workspace admin |
| `*:read` | Read any resource type | Global read-only |
| `*` | All permissions | Super admin |

### Permission Checking Flow

```mermaid
sequenceDiagram
    participant Client
    participant Axum as Axum Server
    participant CtxMW as CtxMiddleware
    participant Handler
    participant Svc as Service Layer
    participant AuthV as AuthValidator
    participant Store

    Client->>Axum: POST /accounts/create (Bearer token)
    Axum->>CtxMW: Extract & decode JWT
    CtxMW->>CtxMW: Check blacklist
    CtxMW->>Handler: CoreCtx (account_id, workspace, perms)
    Handler->>Svc: account_service.create(ctx, params)
    Svc->>AuthV: validate_ctx_perms(ctx, "account:create")
    AuthV->>AuthV: PermissionChecker.has("account:create")?
    AuthV-->>Svc: Allowed / Denied
    Svc->>Store: Insert account
    Store-->>Svc: Created account
    Svc-->>Handler: Account object
    Handler-->>Client: { success: true, data: { ... } }
```

### Built-in Permission Constants

The system defines these permission constants that services require for CRUD operations:

| Category | Permission | Action |
|----------|-----------|--------|
| Account | `account:readSelf` | Read own profile |
| Account | `account:updateSelf` | Update own profile |
| Account | `account:deleteSelf` | Delete own account |
| Account | `account:readAny` | Read any account |
| Account | `account:updateAny` | Update any account |
| Account | `account:deleteAny` | Delete any account |
| Workspace | `workspace:list` | List workspaces |
| Workspace | `workspace:create` | Create workspace |
| Workspace | `workspace:read` | Read workspace |
| Workspace | `workspace:update` | Update workspace |
| Workspace | `workspace:delete` | Delete workspace |
| Project | `project:list` | List projects |
| Project | `project:create` | Create project |
| Project | `project:read` | Read project |
| Project | `project:update` | Update project |
| Project | `project:delete` | Delete project |
| Membership | `membership:list` | List memberships |
| Membership | `membership:invite` | Invite member |
| Membership | `membership:updateStatus` | Change membership status |
| Membership | `membership:manageRole` | Assign/remove roles |
| Membership | `membership:delete` | Remove member |
| Membership | `membership:readSelf` | Read own memberships |
| Role | `role:list` | List roles |
| Role | `role:create` | Create role |
| Role | `role:update` | Update role |
| Role | `role:delete` | Delete role |
| Permission | `permission:read` | Read permissions |
| Permission | `permission:manageConfig` | Create/update/delete permissions |
| Credential | `credential:manageSelf` | Manage own credentials |
| Credential | `credential:resetAny` | Reset any credential |
| Token | `token:revokeSelf` | Revoke own tokens |
| Token | `token:revokeAny` | Revoke any token |

## Token Blacklisting

Tokens can be revoked by blacklisting their SHA-256 hash. The blacklist is checked on every request by the `CtxMiddleware`.

Blacklisted token entries include:

- The SHA-256 hash of the JWT
- The owning account
- The workspace
- Expiration time
- An optional reason

See the [Auth API](api/auth.md) for token revocation endpoints (`POST /auth/revoke`, `POST /auth/blacklist`).

## Workspace Scoping

Every authenticated request operates within a **workspace context**. OxideAuth resolves the target workspace using one of two mechanisms:

### 1. Token-Scoped Workspace (Standard)

For standard user tokens, the workspace ID is embedded in the JWT as the `ws` claim. The `CtxMiddleware` extracts the workspace directly from the token, and the service layer enforces that:

1. The requested workspace exists
2. The caller has `workspace:describe` permission on it
3. The caller has the specific CRUD permission for the operation

**No additional header is required** — the workspace is determined entirely by the token.

### 2. Global-Scope Tokens with `X-Workspace-Id` Header

Global (root) tokens operate across all workspaces. Because the token itself does not specify a target workspace, the client must explicitly provide one via the `X-Workspace-Id` HTTP header.

| Header | Required For | Description |
|--------|:------------:|-------------|
| `X-Workspace-Id` | Global tokens only | UUID of the workspace to operate on |

**Behavior:**

- If the token is **global/root scoped** and the `X-Workspace-Id` header is **present**, the middleware overrides the scoped workspace with the provided UUID.
- If the token is **global/root scoped** and the `X-Workspace-Id` header is **missing**, the API returns `400 Bad Request`:
  ```json
  {
    "success": false,
    "status": 400,
    "message": "X-Workspace-Id header required for global-scope tokens"
  }
  ```
- If the token is **workspace-scoped**, the `X-Workspace-Id` header is **ignored** — the token's embedded workspace always takes precedence.

### Example: Using Global Tokens

```http
POST /accounts/create HTTP/1.1
Authorization: Bearer <global_token>
X-Workspace-Id: 550e8400-e29b-41d4-a716-446655440000
Content-Type: application/json

{
  "email": "alice@example.com",
  "password": "SecureP@ssw0rd!",
  "name": "Alice Johnson"
}
```

### Tenant Isolation

This dual-mode scoping ensures strict tenant isolation — users in one workspace cannot access resources in another. Global tokens are intended for administrative and cross-tenant operations only.
