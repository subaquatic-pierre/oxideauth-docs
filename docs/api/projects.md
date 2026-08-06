# Project API

Projects are scoped work areas within workspaces. They can represent applications, microservices, or team boundaries.

**All endpoints require** `Authorization: Bearer <token>`.

---

## Create Project

`POST /projects/create`

Creates a new project within a workspace. The name must be unique within the workspace.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | Parent workspace |
| `name` | string | Yes | Project name (unique per workspace) |
| `code` | string | No | Short code identifier |
| `description` | string | No | Optional description |
| `config` | object | Yes | Project configuration (`schema_version` required) |
| `tags` | string[] | Yes | Categorization tags |
| `meta` | object | Yes | Metadata (`schema_version` required) |

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Web Application",
  "code": "web-app",
  "description": "Main customer-facing web application",
  "config": { "schema_version": "1.0" },
  "tags": ["frontend", "public"],
  "meta": { "schema_version": "1.0" }
}
```

### Response

Returns the created `Project` object:

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Project identifier |
| `name` | string | Display name |
| `code` | string? | Short code |
| `description` | string? | Description |
| `config` | object | Project config |
| `tags` | string[] | Tags |
| `meta` | object | Metadata |
| `created_at` | RFC 3339 | Creation timestamp |
| `updated_at` | RFC 3339? | Last update timestamp |

---

## Describe Project

`POST /projects/describe`

Retrieves a project by `id` or `code`.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | Workspace context |
| `id` | UUID | No* | Project ID |
| `code` | string | No* | Project code |

\* Either `id` or `code` must be provided.

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "code": "web-app"
}
```

### Response

Full `Project` object.

---

## List Projects

`POST /projects/list`

Lists projects within a workspace.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | Workspace context |
| `filter` | object | No | Filter (`tags` + `fields`) |
| `options` | object | No | Pagination (`limit`, `offset`, `order_bys`) |

### Filter Fields (`filter.fields`)

`id`, `workspace_id`, `name`, `code`, `description`

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "filter": { "tags": [], "fields": {} },
  "options": { "limit": 10, "offset": 0, "order_bys": "!created_at" }
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "projects": [ ... ],
    "metadata": { "total": 3, "count": 3, "offset": 0, "limit": 10, "order_bys": ["!created_at"] }
  }
}
```

---

## Update Project

`POST /projects/update`

Updates project fields. All fields except `workspace_id` are optional.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | Workspace context |
| `id` | UUID | No* | Project ID |
| `code` | string | No* | Current code (to identify) |
| `name` | string | No | New name |
| `new_code` | string | No | Rename code |
| `description` | string | No | New description |
| `config` | object | No | New config |
| `tags` | string[] | No | Replacement tags |
| `meta` | object | No | New metadata |

\* Either `id` or `code` must be provided.

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "code": "web-app",
  "name": "Web Application v2",
  "description": "Updated description"
}
```

### Response

Updated `Project` object.

---

## Delete Project

`POST /projects/delete`

Deletes a project by `id` or `code`.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | Workspace context |
| `id` | UUID | No* | Project ID |
| `code` | string | No* | Project code |

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "code": "web-app"
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "code": "web-app",
    "name": "Web Application"
  }
}
```
