# Account API

User account management. Accounts are global identities that can belong to multiple workspaces via [memberships](memberships.md).

**All endpoints require** `Authorization: Bearer <token>`.

---

## Create Account

`POST /accounts/create`

Creates a new user account within a workspace. The email must be globally unique.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `email` | string | Yes | Unique email address |
| `password` | string | Yes | Account password (hashed with Argon2 server-side) |
| `workspace_id` | UUID | Yes | The workspace to associate with |
| `name` | string | Yes | Display name |
| `description` | string | No | Optional description |
| `avatar_url` | string | No | Avatar image URL |
| `tags` | string[] | No | Categorization tags |
| `meta` | object | No | Metadata (`schema_version` required if provided) |

### Example Request

```json
{
  "email": "alice@example.com",
  "password": "SecureP@ssw0rd!",
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Alice Johnson",
  "description": "Engineering team lead",
  "avatar_url": "https://example.com/avatars/alice.png",
  "tags": ["engineering", "staff"],
  "meta": { "schema_version": "1.0" }
}
```

### Response

Returns the created `Account` object:

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Account identifier |
| `email` | string | Email address |
| `name` | string | Display name |
| `description` | string? | Optional description |
| `avatar_url` | string? | Avatar URL |
| `enabled` | boolean | Whether the account is active |
| `verified` | boolean | Whether the email is verified |
| `tags` | string[] | Tags |
| `meta` | object | Metadata |
| `created_at` | RFC 3339 | Creation timestamp |
| `updated_at` | RFC 3339? | Last update timestamp |

---

## Describe Account

`POST /accounts/describe`

Retrieves an account by `id` or `email`.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | Workspace context |
| `id` | UUID | No* | Account ID |
| `email` | string | No* | Account email |

\* Either `id` or `email` must be provided.

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "alice@example.com"
}
```

### Response

Full `Account` object.

---

## List Accounts

`POST /accounts/list`

Lists accounts in a workspace with optional filtering and pagination.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | Workspace context |
| `filter` | object | No | Filter parameters |
| `options` | object | No | Pagination options |

### Filter Fields (`filter.fields`)

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Account ID |
| `email` | string | Email address |
| `name` | string | Display name |
| `description` | string | Description text |
| `avatar_url` | string | Avatar URL |
| `verified` | boolean | Email verified |
| `enabled` | boolean | Account active |
| `created_by` | UUID | Creator account ID |
| `created_at` | datetime | Creation time |
| `updated_by` | UUID | Last updater account ID |
| `updated_at` | datetime | Last update time |

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "filter": {
    "tags": ["engineering"],
    "fields": {}
  },
  "options": {
    "limit": 10,
    "offset": 0,
    "order_bys": "!created_at"
  }
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "accounts": [ ... ],
    "metadata": {
      "total": 15,
      "count": 10,
      "offset": 0,
      "limit": 10,
      "order_bys": ["!created_at"]
    }
  }
}
```

---

## Update Account

`POST /accounts/update`

Updates account fields. All fields except `workspace_id` are optional.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | Workspace context |
| `id` | UUID | No* | Account ID |
| `email` | string | No* | Current email (to identify account) |
| `name` | string | No | New display name |
| `description` | string | No | New description |
| `avatar_url` | string | No | New avatar URL |
| `enabled` | boolean | No | Enable/disable account |
| `verified` | boolean | No | Verify/unverify account |
| `tags` | string[] | No | Replacement tags |
| `meta` | object | No | New metadata |

\* Either `id` or `email` must be provided to identify the account.

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "alice@example.com",
  "name": "Alice Johnson-Smith",
  "description": "Senior Engineering Lead",
  "tags": ["engineering", "staff", "leadership"]
}
```

### Response

Updated `Account` object.

---

## Delete Account

`POST /accounts/delete`

Deletes an account by `id` or `email`.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | Workspace context |
| `id` | UUID | No* | Account ID |
| `email` | string | No* | Account email |

\* Either `id` or `email` must be provided.

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "alice@example.com"
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000"
  }
}
```
