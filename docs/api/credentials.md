# Credential API

Authentication credential management. Credentials link accounts to authentication providers.

!!! note "No Create Endpoint"
    Credentials are created implicitly during account registration or OAuth flows. This API provides describe, list, update, and delete operations.

**All endpoints require** `Authorization: Bearer <token>`.

---

## Credential Types

### Kind

| Kind | Description |
|------|-------------|
| `password` | Local password authentication (Argon2 hashed) |
| `oauth` | OAuth2 provider authentication |
| `sso` | Single Sign-On provider |
| `api_key` | API key authentication |

### Provider

| Provider | Description |
|----------|-------------|
| `local` | Local password |
| `google` | Google OAuth2 |
| `github` | GitHub OAuth |

### Status

| Status | Description |
|--------|-------------|
| `active` | Credential is valid and usable |
| `revoked` | Credential has been revoked |
| `pending` | Awaiting verification (e.g., email not confirmed) |

---

## Describe Credential

`POST /credentials/describe`

Retrieves a credential by ID.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `id` | UUID | Yes | Credential ID |
| `account_id` | UUID | Yes | Owning account |
| `workspace_id` | UUID | Yes | Workspace context |
| `provider_id` | string | No | External provider ID |
| `email` | string | No | Associated email |

### Example Request

```json
{
  "id": "bb0e8400-e29b-41d4-a716-446655440006",
  "account_id": "880e8400-e29b-41d4-a716-446655440003",
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Response

Returns the `Credential` object:

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Credential identifier |
| `account_id` | UUID | Owning account |
| `workspace_id` | UUID | Workspace |
| `kind` | string | `"password"`, `"oauth"`, `"sso"`, or `"api_key"` |
| `provider` | string | `"local"`, `"google"`, or `"github"` |
| `status` | string | `"active"`, `"revoked"`, or `"pending"` |
| `provider_id` | string? | External provider identifier |
| `email` | string? | Associated email |
| `last_used_at` | RFC 3339? | Last authentication timestamp |
| `tags` | string[] | Tags |
| `meta` | object | Metadata |
| `created_at` | RFC 3339 | Creation timestamp |
| `updated_at` | RFC 3339? | Last update timestamp |

---

## List Credentials

`POST /credentials/list`

Lists credentials within a workspace.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | Workspace context |
| `filter` | object | No | Filter parameters |
| `options` | object | No | Pagination options |

### Filter Fields

`id`, `account_id`, `workspace_id`, `kind`, `provider`, `status`, `provider_id`, `email`

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "filter": {
    "tags": [],
    "fields": { "status": "active" }
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
    "credentials": [ ... ],
    "metadata": { "total": 4, "count": 4, ... }
  }
}
```

---

## Update Credential

`POST /credentials/update`

Updates a credential's fields. All fields except `id`, `account_id`, and `workspace_id` are optional.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `id` | UUID | Yes | Credential ID |
| `account_id` | UUID | Yes | Owning account |
| `workspace_id` | UUID | Yes | Workspace context |
| `kind` | string | No | New credential kind |
| `provider` | string | No | New provider |
| `status` | string | No | `"active"`, `"revoked"`, or `"pending"` |
| `provider_id` | string | No | External provider ID |
| `email` | string | No | Associated email |
| `new_provider_id` | string | No | Replace external provider ID |
| `new_email` | string | No | Replace associated email |
| `secret` | string | No | New password/secret |
| `last_used_at` | RFC 3339 | No | Last usage timestamp |
| `tags` | string[] | No | Replacement tags |
| `meta` | object | No | New metadata |

### Example Request

```json
{
  "id": "bb0e8400-e29b-41d4-a716-446655440006",
  "account_id": "880e8400-e29b-41d4-a716-446655440003",
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "revoked",
  "tags": ["revoked"]
}
```

### Response

Updated `Credential` object.

---

## Delete Credential

`POST /credentials/delete`

Deletes a credential by ID.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `id` | UUID | Yes | Credential ID |
| `account_id` | UUID | Yes | Owning account |
| `workspace_id` | UUID | Yes | Workspace context |
| `provider_id` | string | No | External provider ID |
| `email` | string | No | Associated email |

### Example Request

```json
{
  "id": "bb0e8400-e29b-41d4-a716-446655440006",
  "account_id": "880e8400-e29b-41d4-a716-446655440003",
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "id": "bb0e8400-e29b-41d4-a716-446655440006"
  }
}
```
