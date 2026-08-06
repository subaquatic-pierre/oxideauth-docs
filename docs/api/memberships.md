# Membership API

Memberships link [accounts](accounts.md) to workspaces or projects, assigning [roles](roles.md) that grant permissions.

**All endpoints require** `Authorization: Bearer <token>`.

---

## Membership Scopes

| Scope | Description |
|-------|-------------|
| `workspace` | Account is a member of the entire workspace |
| `project` | Account is a member of a specific project within the workspace |

## Membership Statuses

| Status | Description |
|--------|-------------|
| `invited` | Pending invitation, not yet active |
| `active` | Active membership with granted permissions |
| `suspended` | Temporarily disabled membership |

---

## Create Membership

`POST /memberships/create`

Creates a membership linking an account to a workspace or project.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `account_id` | UUID | Yes | Account to link |
| `workspace_id` | UUID | Yes | Workspace context |
| `scope` | string | Yes | `"workspace"` or `"project"` |
| `status` | string | Yes | `"invited"`, `"active"`, or `"suspended"` |
| `project_id` | UUID | No* | Project ID (required if scope is `"project"`) |
| `role_ids` | UUID[] | Yes | Roles to assign |
| `tags` | string[] | Yes | Categorization tags |
| `meta` | object | Yes | Metadata (`schema_version` required) |

\* Required when `scope` is `"project"`.

### Example Request

```json
{
  "account_id": "880e8400-e29b-41d4-a716-446655440003",
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "scope": "workspace",
  "status": "active",
  "role_ids": [
    "770e8400-e29b-41d4-a716-446655440002"
  ],
  "tags": ["member"],
  "meta": { "schema_version": "1.0" }
}
```

### Project-Scoped Example

```json
{
  "account_id": "880e8400-e29b-41d4-a716-446655440003",
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "scope": "project",
  "status": "active",
  "project_id": "990e8400-e29b-41d4-a716-446655440004",
  "role_ids": ["770e8400-e29b-41d4-a716-446655440002"],
  "tags": ["contributor"],
  "meta": { "schema_version": "1.0" }
}
```

### Response

Returns the created `Membership` object with nested roles:

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Membership identifier |
| `account_id` | UUID | Linked account |
| `workspace_id` | UUID | Workspace |
| `project_id` | UUID? | Project (if project-scoped) |
| `scope` | string | `"workspace"` or `"project"` |
| `status` | string | `"invited"`, `"active"`, or `"suspended"` |
| `roles` | Role[] | Assigned roles with permissions |
| `tags` | string[] | Tags |
| `meta` | object | Metadata |
| `created_at` | RFC 3339 | Creation timestamp |
| `updated_at` | RFC 3339? | Last update timestamp |

---

## Describe Membership

`POST /memberships/describe`

Retrieves a membership by ID.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `id` | UUID | Yes | Membership ID |
| `workspace_id` | UUID | Yes | Workspace context |

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "id": "aa0e8400-e29b-41d4-a716-446655440005"
}
```

### Response

Full `Membership` object with nested roles.

---

## List Memberships

`POST /memberships/list`

Lists memberships within a workspace.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | Workspace context |
| `filter` | object | No | Filter parameters |
| `options` | object | No | Pagination options |

### Filter Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Membership ID |
| `account_id` | UUID | Account ID |
| `workspace_id` | UUID | Workspace ID |
| `scope` | string | `"workspace"` or `"project"` |
| `status` | string | `"invited"`, `"active"`, `"suspended"` |
| `project_id` | UUID | Project ID |

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
    "memberships": [ ... ],
    "metadata": { "total": 8, "count": 8, ... }
  }
}
```

---

## Update Membership

`POST /memberships/update`

Updates membership fields. All fields except `id` and `workspace_id` are optional.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `id` | UUID | Yes | Membership ID |
| `workspace_id` | UUID | Yes | Workspace context |
| `status` | string | No | `"invited"`, `"active"`, or `"suspended"` |
| `scope` | string | No | `"workspace"` or `"project"` |
| `project_id` | UUID | No | Project ID (for project scope) |
| `tags` | string[] | No | Replacement tags |
| `meta` | object | No | New metadata |

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "id": "aa0e8400-e29b-41d4-a716-446655440005",
  "status": "suspended",
  "tags": ["member", "suspended"]
}
```

### Response

Updated `Membership` object.

---

## Delete Membership

`POST /memberships/delete`

Deletes a membership by ID. This removes the account's access to the workspace/project.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `id` | UUID | Yes | Membership ID |
| `workspace_id` | UUID | Yes | Workspace context |

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "id": "aa0e8400-e29b-41d4-a716-446655440005"
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "id": "aa0e8400-e29b-41d4-a716-446655440005"
  }
}
```
