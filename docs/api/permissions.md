# Permission API

Fine-grained permission definitions. Permissions use a `resource:action` naming convention and are bundled into [roles](roles.md).

**All endpoints require** `Authorization: Bearer <token>`.

---

## Permission Naming Convention

Permissions follow the `resource:action` format with wildcard support:

| Pattern | Matches |
|---------|---------|
| `account:readAny` | Read any account |
| `workspace:*` | All workspace operations |
| `*:read` | Read on any resource |
| `*` | All permissions |

The `code` field provides a machine-readable shorthand (e.g., `account.read_any`).

---

## Create Permission

`POST /permissions/create`

Creates a new permission in a workspace. The name must be unique within the workspace.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | Workspace context |
| `name` | string | Yes | Permission name (e.g., `"account:readAny"`) |
| `code` | string | No | Machine-readable code |
| `description` | string | No | Human-readable description |
| `tags` | string[] | Yes | Categorization tags |
| `meta` | object | Yes | Metadata (`schema_version` required) |

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "account:readAny",
  "code": "account.read_any",
  "description": "Allows reading any account in the workspace",
  "tags": ["account", "read"],
  "meta": { "schema_version": "1.0" }
}
```

### Response

Returns the created `Permission` object:

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Permission identifier |
| `name` | string | Permission name |
| `code` | string? | Machine-readable code |
| `description` | string? | Description |
| `tags` | string[] | Tags |
| `meta` | object | Metadata |
| `created_at` | RFC 3339 | Creation timestamp |
| `updated_at` | RFC 3339? | Last update timestamp |

---

## Describe Permission

`POST /permissions/describe`

Retrieves a permission by `id` or `code`.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | Workspace context |
| `id` | UUID | No* | Permission ID |
| `code` | string | No* | Permission code |

\* Either `id` or `code` must be provided.

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "code": "account.read_any"
}
```

### Response

Full `Permission` object.

---

## List Permissions

`POST /permissions/list`

Lists permissions within a workspace.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | Workspace context |
| `filter` | object | No | Filter parameters |
| `options` | object | No | Pagination options |

### Filter Fields

`id`, `workspace_id`, `name`, `code`, `description`

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "filter": { "tags": ["account"], "fields": {} },
  "options": { "limit": 20, "offset": 0, "order_bys": "name" }
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "permissions": [ ... ],
    "metadata": { "total": 22, "count": 20, ... }
  }
}
```

---

## Update Permission

`POST /permissions/update`

Updates permission metadata.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `id` | UUID | Yes | Permission ID |
| `workspace_id` | UUID | Yes | Workspace context |
| `name` | string | No | New name |
| `code` | string | No | New code |
| `description` | string | No | New description |
| `tags` | string[] | No | Replacement tags |
| `meta` | object | No | New metadata |

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "id": "660e8400-e29b-41d4-a716-446655440001",
  "description": "Allows reading any account (updated)"
}
```

### Response

Updated `Permission` object.

---

## Delete Permission

`POST /permissions/delete`

Deletes a permission by ID.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `id` | UUID | Yes | Permission ID |
| `workspace_id` | UUID | Yes | Workspace context |

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "id": "660e8400-e29b-41d4-a716-446655440001"
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "id": "660e8400-e29b-41d4-a716-446655440001"
  }
}
```
