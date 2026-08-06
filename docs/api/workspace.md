# Workspace API

Workspaces are the top-level multi-tenancy containers. Every resource (accounts, projects, roles, permissions) belongs to a workspace.

**All endpoints require** `Authorization: Bearer <token>`.

---

## Create Workspace

`POST /workspace/create`

Creates a new workspace. The slug must be globally unique.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `name` | string | Yes | Display name |
| `slug` | string | Yes | URL-friendly unique identifier |
| `description` | string | No | Optional description |
| `config` | object | Yes | Workspace configuration (`schema_version` required) |
| `tags` | string[] | Yes | Categorization tags |
| `meta` | object | Yes | Extensible metadata (`schema_version` required) |

### Example Request

```json
{
  "name": "My Organization",
  "slug": "my-org",
  "description": "Primary workspace for My Organization",
  "config": { "schema_version": "1.0" },
  "tags": ["production", "primary"],
  "meta": { "schema_version": "1.0" }
}
```

### Response

Returns the created `Workspace` object:

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Workspace identifier |
| `name` | string | Display name |
| `slug` | string | Unique slug |
| `description` | string? | Optional description |
| `config` | object | Workspace config |
| `tags` | string[] | Tags |
| `meta` | object | Metadata |
| `created_at` | RFC 3339 | Creation timestamp |
| `updated_at` | RFC 3339? | Last update timestamp |

---

## Describe Workspace

`POST /workspace/describe`

Retrieves a workspace by `id` or `slug`.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `id` | UUID | No* | Workspace ID |
| `slug` | string | No* | Workspace slug |

\* Either `id` or `slug` must be provided.

### Example Request

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000"
}
```

or

```json
{
  "slug": "my-org"
}
```

### Response

Full `Workspace` object (same schema as Create response).

---

## List Workspaces

`POST /workspace/list`

Lists all workspaces with optional filtering and pagination.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `filter` | object | No | Filter parameters |
| `options` | object | No | Pagination options |

### Filter Fields (`filter.fields`)

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Filter by workspace ID |
| `name` | string | Filter by name |
| `slug` | string | Filter by slug |
| `description` | string | Filter by description |

### Options

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `limit` | integer | — | Page size |
| `offset` | integer | — | Records to skip |
| `order_bys` | string | — | Sort order (`"created_at"` for ASC, `"!created_at"` for DESC) |

### Example Request

```json
{
  "filter": {
    "tags": [],
    "fields": {}
  },
  "options": {
    "limit": 10,
    "offset": 0,
    "order_bys": "!created_at"
  }
}
```

!!! note "Filter Constraints"
    You cannot provide both `filter.tags` and `filter.fields` simultaneously.

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "workspaces": [ ... ],
    "metadata": {
      "total": 5,
      "count": 5,
      "offset": 0,
      "limit": 10,
      "order_bys": ["!created_at"]
    }
  }
}
```

---

## Update Workspace

`POST /workspace/update`

Updates workspace fields. All fields except the identifier are optional — only include what you want to change.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `id` | UUID | No* | Workspace ID to update |
| `slug` | string | No* | Slug of workspace to update |
| `name` | string | No | New display name |
| `description` | string | No | New description |
| `config` | object | No | New config |
| `tags` | string[] | No | Replacement tags |
| `meta` | object | No | New metadata |

\* Either `id` or `slug` must be provided to identify the workspace.

### Example Request

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "My Organization (Updated)",
  "description": "Updated description"
}
```

### Response

Updated `Workspace` object.

---

## Delete Workspace

`POST /workspace/delete`

Deletes a workspace. **This is a destructive operation.**

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `id` | UUID | No* | Workspace ID |
| `slug` | string | No* | Workspace slug |

\* Either `id` or `slug` must be provided.

### Example Request

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "slug": "my-org",
    "name": "My Organization"
  }
}
```
