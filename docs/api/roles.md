# Role API

Roles bundle [permissions](permissions.md) and [policies](policies.md) together and are assigned to accounts through [memberships](memberships.md).

**All endpoints require** `Authorization: Bearer <token>`.

---

## Create Role

`POST /roles/create`

Creates a new role with associated permissions and policies. The name must be unique within the workspace.

### Request Body

```json
{
  "name": "Admin",                                             // string (required) - Role name (unique per workspace)
  "description": "Full administrative access",                 // string (optional) - Optional description
  "permission_ids": ["660e8400-e29b-41d4-a716-446655440001"],  // UUID[] (required) - Permissions to attach
  "policy_ids": ["cc0e8400-e29b-41d4-a716-446655440006"],      // UUID[] (required) - Policies to attach
  "tags": ["admin"],                                           // string[] (required) - Categorization tags
  "meta": { "schema_version": "1.0" }                          // object (required) - Metadata (schema_version required)
}
```

### Response

Returns the created `Role` object with nested permissions and policies:

```json
{
  "id": "770e8400-e29b-41d4-a716-446655440002",       // UUID - Role identifier
  "name": "Admin",                                    // string - Role name
  "description": "Full administrative access",        // string? - Description
  "permissions": [                                    // Permission[] - Attached permission objects
    { "id": "660e8400-e29b-41d4-a716-446655440001" }  // object - A single permission object
  ],
  "policies": [                                       // Policy[] - Attached policy objects
    { "id": "cc0e8400-e29b-41d4-a716-446655440006" }  // object - A single policy object
  ],
  "tags": ["admin"],                                  // string[] - Categorization tags
  "meta": { "schema_version": "1.0" },                // object - Metadata
  "created_at": "2024-01-15T10:30:00Z",               // RFC 3339 - Creation timestamp
  "updated_at": null                                  // RFC 3339? - Last update, null if never updated
}
```

---

## Describe Role

`POST /roles/describe`

Retrieves a role by ID.

### Request Body

```json
{
  "id": "770e8400-e29b-41d4-a716-446655440002"  // UUID (required) - Role ID
}
```

### Response

Full `Role` object with nested permissions and policies:

```json
{
  "id": "770e8400-e29b-41d4-a716-446655440002",       // UUID - Role identifier
  "name": "Admin",                                    // string - Role name
  "description": "Full administrative access",        // string? - Description
  "permissions": [                                    // Permission[] - Attached permission objects
    { "id": "660e8400-e29b-41d4-a716-446655440001" }  // object - A single permission object
  ],
  "policies": [                                       // Policy[] - Attached policy objects
    { "id": "cc0e8400-e29b-41d4-a716-446655440006" }  // object - A single policy object
  ],
  "tags": ["admin"],                                  // string[] - Categorization tags
  "meta": { "schema_version": "1.0" },                // object - Metadata
  "created_at": "2024-01-15T10:30:00Z",               // RFC 3339 - Creation timestamp
  "updated_at": null                                  // RFC 3339? - Last update, null if never updated
}
```

---

## List Roles

`POST /roles/list`

Lists roles within a workspace.

### Request Body

```json
{
  "filter": {                   // object (optional) - Filter parameters
    "tags": ["admin"],          // string[] (optional) - Only include roles with all listed tags
    "fields": {}                // object (optional) - Field filters (see Filter Fields below)
  },
  "options": {                  // object (optional) - Pagination options
    "limit": 10,                // integer (optional) - Maximum number of items to return
    "offset": 0,                // integer (optional) - Number of items to skip
    "order_bys": "!created_at"  // string (optional) - Sort order; prefix `!` for descending
  }
}
```

!!! note "Filter Combination"
    `filter.tags` and `filter.fields` are combined via **AND** logic — both conditions must match for a record to be returned.

!!! tip "Empty Body"
    Sending an empty body `{}` is valid — no filters are applied and default list options are used (limit=100, newest first).

### Filter Fields

`id`, `workspace_id`, `name`, `description`

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

Updates role fields. All fields except `id` are optional.

### Request Body

```json
{
  "id": "770e8400-e29b-41d4-a716-446655440002",                // UUID (required) - Role ID
  "name": "Super Admin",                                       // string (optional) - New name
  "description": "Elevated administrative access",             // string (optional) - New description
  "permission_ids": ["660e8400-e29b-41d4-a716-446655440001"],  // UUID[] (optional) - Replaces all attached permissions
  "policy_ids": ["cc0e8400-e29b-41d4-a716-446655440006"],      // UUID[] (optional) - Replaces all attached policies
  "tags": ["admin"],                                           // string[] (optional) - Replacement tags
  "meta": { "schema_version": "1.0" }                          // object (optional) - New metadata
}
```

!!! warning "Permission Replacement"
    Providing `permission_ids` will **replace** all existing permissions on the role, not append to them.

!!! warning "Policy Replacement"
    Providing `policy_ids` will **replace** all existing policies on the role, not append to them.

### Response

Updated `Role` object:

```json
{
  "id": "770e8400-e29b-41d4-a716-446655440002",       // UUID - Role identifier
  "name": "Admin",                                    // string - Role name
  "description": "Full administrative access",        // string? - Description
  "permissions": [                                    // Permission[] - Attached permission objects
    { "id": "660e8400-e29b-41d4-a716-446655440001" }  // object - A single permission object
  ],
  "policies": [                                       // Policy[] - Attached policy objects
    { "id": "cc0e8400-e29b-41d4-a716-446655440006" }  // object - A single policy object
  ],
  "tags": ["admin"],                                  // string[] - Categorization tags
  "meta": { "schema_version": "1.0" },                // object - Metadata
  "created_at": "2024-01-15T10:30:00Z",               // RFC 3339 - Creation timestamp
  "updated_at": null                                  // RFC 3339? - Last update, null if never updated
}
```

---

## Delete Role

`POST /roles/delete`

Deletes a role by ID.

### Request Body

```json
{
  "id": "770e8400-e29b-41d4-a716-446655440002"  // UUID (required) - Role ID
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
