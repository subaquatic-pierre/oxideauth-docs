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

```json
{
  "account_id": "880e8400-e29b-41d4-a716-446655440003",    // UUID (required) - Account to link
  "scope": "workspace",                                     // string (required) - "workspace" or "project"
  "status": "active",                                       // string (required) - "invited", "active", or "suspended"
  "project_id": "990e8400-e29b-41d4-a716-446655440004",     // UUID (optional*) - Project ID (required if scope is "project")
  "role_ids": ["770e8400-e29b-41d4-a716-446655440002"],     // UUID[] (required) - Roles to assign
  "tags": ["member"],                                       // string[] (required) - Categorization tags
  "meta": {                                                 // object (required) - Metadata (schema_version required)
    "schema_version": "1.0"                                   // string (required) - Metadata schema version
  }
}
```

\* Required when `scope` is `"project"`.

### Project-Scoped Example

```json
{
  "account_id": "880e8400-e29b-41d4-a716-446655440003",
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

```json
{
  "id": "aa0e8400-e29b-41d4-a716-446655440005",              // UUID - Membership identifier
  "account_id": "880e8400-e29b-41d4-a716-446655440003",      // UUID - Linked account
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",    // UUID - Workspace
  "project_id": "990e8400-e29b-41d4-a716-446655440004",      // UUID? - Project (if project-scoped)
  "scope": "workspace",                                       // string - "workspace" or "project"
  "status": "active",                                         // string - "invited", "active", or "suspended"
  "roles": [                                                  // Role[] - Assigned roles with permissions
    {
      "id": "770e8400-e29b-41d4-a716-446655440002"             // UUID - Role identifier
    }
  ],
  "tags": ["member"],                                         // string[] - Tags
  "meta": {                                                   // object - Metadata
    "schema_version": "1.0"                                     // string - Schema version
  },
  "created_at": "2024-01-15T10:30:00Z",                       // RFC 3339 - Creation timestamp
  "updated_at": "2024-01-15T10:30:00Z"                        // RFC 3339? - Last update timestamp
}
```

---

## Describe Membership

`POST /memberships/describe`

Retrieves a membership by ID.

### Request Body

```json
{
  "id": "aa0e8400-e29b-41d4-a716-446655440005"    // UUID (required) - Membership ID
}
```

### Response

Full `Membership` object with nested roles.

---

## List Memberships

`POST /memberships/list`

Lists memberships within a workspace.

### Request Body

```json
{
  "filter": {                                    // object (optional) - Filter parameters
    "tags": [],                                    // string[] (optional) - Tags to filter by
    "fields": { "status": "active" }               // object (optional) - Field filters
  },
  "options": {                                   // object (optional) - Pagination options
    "limit": 10,                                   // integer (optional) - Page size
    "offset": 0,                                   // integer (optional) - Page offset
    "order_bys": "!created_at"                     // string (optional) - Sort order
  }
}
```

!!! note "Filter Combination"
    `filter.tags` and `filter.fields` are combined via **AND** logic — both conditions must match for a record to be returned.

!!! tip "Empty Body"
    Sending an empty body `{}` is valid — no filters are applied and default list options are used (limit=100, newest first).

### Filter Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Membership ID |
| `account_id` | UUID | Account ID |
| `workspace_id` | UUID | Workspace ID |
| `scope` | string | `"workspace"` or `"project"` |
| `status` | string | `"invited"`, `"active"`, `"suspended"` |
| `project_id` | UUID | Project ID |

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

Updates membership fields. All fields except `id` are optional.

### Request Body

```json
{
  "id": "aa0e8400-e29b-41d4-a716-446655440005",          // UUID (required) - Membership ID
  "status": "suspended",                                   // string (optional) - "invited", "active", or "suspended"
  "scope": "workspace",                                    // string (optional) - "workspace" or "project"
  "project_id": "990e8400-e29b-41d4-a716-446655440004",   // UUID (optional) - Project ID (for project scope)
  "tags": ["member", "suspended"],                         // string[] (optional) - Replacement tags
  "meta": {                                                // object (optional) - New metadata
    "schema_version": "1.0"                                  // string (optional) - Schema version
  }
}
```

### Response

Updated `Membership` object.

---

## Delete Membership

`POST /memberships/delete`

Deletes a membership by ID. This removes the account's access to the workspace/project.

### Request Body

```json
{
  "id": "aa0e8400-e29b-41d4-a716-446655440005"    // UUID (required) - Membership ID
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
