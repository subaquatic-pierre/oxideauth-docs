# Token API

Token blacklist management. When a JWT is revoked, its SHA-256 hash is stored in the blacklist. The `CtxMiddleware` checks the blacklist on every authenticated request.

!!! note "No Create or Update"
    Tokens are created during authentication and blacklisted through the revocation process. This API provides describe, list, and delete (un-revoke) operations.

**All endpoints require** `Authorization: Bearer <token>`.

---

## Token Kinds

| Kind | Description |
|------|-------------|
| `auth` | Standard access token |
| `password_reset` | Password reset token |

---

## Describe Token

`POST /tokens/describe`

Retrieves a blacklisted token entry by ID.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `id` | UUID | Yes | Token entry ID |
| `workspace_id` | UUID | Yes | Workspace context |

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "id": "cc0e8400-e29b-41d4-a716-446655440007"
}
```

### Response

Returns the token blacklist entry:

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Entry identifier |
| `kind` | string | `"auth"` or `"password_reset"` |
| `account_id` | UUID | Token owner |
| `workspace_id` | UUID | Workspace |
| `expires_at` | RFC 3339 | Token expiration |
| `reason` | string? | Reason for blacklisting |
| `created_at` | RFC 3339 | Blacklist timestamp |
| `updated_at` | RFC 3339? | Last update timestamp |

!!! info "Hash Storage"
    The actual JWT hash (SHA-256, 32 bytes) is stored internally but not exposed in API responses for security.

---

## List Tokens

`POST /tokens/list`

Lists blacklisted token entries within a workspace.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | Workspace context |
| `filter` | object | No | Filter parameters |
| `options` | object | No | Pagination options |

### Filter Fields

`id`, `kind`, `account_id`, `workspace_id`, `reason`, `expires_at`

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "filter": {
    "tags": [],
    "fields": { "kind": "auth" }
  },
  "options": { "limit": 10, "offset": 0, "order_bys": "!created_at" }
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "tokens": [ ... ],
    "metadata": { "total": 3, "count": 3, ... }
  }
}
```

---

## Delete Token

`POST /tokens/delete`

Removes a token from the blacklist, effectively **un-revoking** it. The original JWT becomes valid again (assuming it hasn't expired).

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `id` | UUID | Yes | Token entry ID |
| `workspace_id` | UUID | Yes | Workspace context |

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "id": "cc0e8400-e29b-41d4-a716-446655440007"
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "id": "cc0e8400-e29b-41d4-a716-446655440007"
  }
}
```
