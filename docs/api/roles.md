# Role API

Roles bundle [permissions](permissions.md) together and are assigned to accounts through [memberships](memberships.md).

**All endpoints require** `Authorization: Bearer <token>`.

---

## Create Role

`POST /roles/create`

Creates a new role with associated permissions. The name must be unique within the workspace.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | Workspace context |
| `name` | string | Yes | Role name (unique per workspace) |
| `description` | string | No | Optional description |
| `permission_ids` | UUID[] | Yes | Permissions to attach |
| `tags` | string[] | Yes | Categorization tags |
| `meta` | object | Yes | Metadata (`schema_version` required) |

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Admin",
  "description": "Full administrative access",
  "permission_ids": [
    "660e8400-e29b-41d4-a716-446655440001"
  ],
  "tags": ["admin"],
  "meta": { "schema_version": "1.0" }
}
```

### Response

Returns the created `Role` object with nested permissions:

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Role identifier |
| `name` | string | Role name |
| `description` | string? | Description |
| `permissions` | Permission[] | Attached permission objects |
| `tags` | string[] | Tags |
| `meta` | object | Metadata |
| `created_at` | RFC 3339 | Creation timestamp |
| `updated_at` | RFC 3339? | Last update timestamp |

---

## Describe Role

`POST /roles/describe`

Retrieves a role by ID.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | Workspace context |
| `id` | UUID | Yes | Role ID |

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "id": "770e8400-e29b-41d4-a716-446655440002"
}
```

### Response

Full `Role` object with nested permissions.

---

## List Roles

`POST /roles/list`

Lists roles within a workspace.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | Workspace context |
| `filter` | object | No | Filter parameters |
| `options` | object | No | Pagination options |

### Filter Fields

`id`, `workspace_id`, `name`, `description`

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "filter": { "tags": ["admin"], "fields": {} },
  "options": { "limit": 10, "offset": 0, "order_bys": "!created_at" }
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "roles": [ ... ],
    "metadata": { "total": 5, "count": 5, ... }
  }
}
```

---

## Update Role

`POST /roles/update`

Updates role fields. All fields except `id` and `workspace_id` are optional.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `id` | UUID | Yes | Role ID |
| `workspace_id` | UUID | Yes | Workspace context |
| `name` | string | No | New name |
| `description` | string | No | New description |
| `permission_ids` | UUID[] | No | Replace attached permissions |
| `tags` | string[] | No | Replacement tags |
| `meta` | object | No | New metadata |

!!! warning "Permission Replacement"
    Providing `permission_ids` will **replace** all existing permissions on the role, not append to them.

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "id": "770e8400-e29b-41d4-a716-446655440002",
  "name": "Super Admin",
  "description": "Elevated administrative access"
}
```

### Response

Updated `Role` object.

---

## Delete Role

`POST /roles/delete`

Deletes a role by ID.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `id` | UUID | Yes | Role ID |
| `workspace_id` | UUID | Yes | Workspace context |

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "id": "770e8400-e29b-41d4-a716-446655440002"
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "id": "770e8400-e29b-41d4-a716-446655440002"
  }
}
```
