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

```json
{
  "name": "account:readAny",                   // string (required) - Permission name (e.g., "account:readAny")
  "code": "account.read_any",                  // string (optional) - Machine-readable code
  "description": "Allows reading any account in the workspace",  // string (optional) - Human-readable description
  "tags": ["account", "read"],                 // string[] (required) - Categorization tags
  "meta": {                                    // object (required) - Metadata (schema_version required)
    "schema_version": "1.0"                      // string (required) - Metadata schema version
  }
}
```

### Response

Returns the created `Permission` object:

```json
{
  "id": "660e8400-e29b-41d4-a716-446655440001",      // UUID - Permission identifier
  "name": "account:readAny",                           // string - Permission name
  "code": "account.read_any",                          // string? - Machine-readable code
  "description": "Allows reading any account in the workspace",  // string? - Description
  "tags": ["account", "read"],                         // string[] - Tags
  "meta": {                                            // object - Metadata
    "schema_version": "1.0"                              // string - Schema version
  },
  "created_at": "2024-01-15T10:30:00Z",                // RFC 3339 - Creation timestamp
  "updated_at": "2024-01-15T10:30:00Z"                 // RFC 3339? - Last update timestamp
}
```

---

## Describe Permission

`POST /permissions/describe`

Retrieves a permission by `id` or `code`.

### Request Body

```json
{
  "id": "660e8400-e29b-41d4-a716-446655440001",   // UUID (optional*) - Permission ID
  "code": "account.read_any"                        // string (optional*) - Permission code
}
```

\* Either `id` or `code` must be provided.

### Response

Full `Permission` object.

---

## List Permissions

`POST /permissions/list`

Lists permissions within a workspace.

### Request Body

```json
{
  "filter": {                              // object (optional) - Filter parameters
    "tags": ["account"],                     // string[] (optional) - Tags to filter by
    "fields": {}                             // object (optional) - Field filters
  },
  "options": {                             // object (optional) - Pagination options
    "limit": 20,                             // integer (optional) - Page size
    "offset": 0,                             // integer (optional) - Page offset
    "order_bys": "name"                      // string (optional) - Sort order
  }
}
```

### Filter Fields

`id`, `workspace_id`, `name`, `code`, `description`

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

```json
{
  "id": "660e8400-e29b-41d4-a716-446655440001",   // UUID (required) - Permission ID
  "name": "account:readAny",                       // string (optional) - New name
  "code": "account.read_any",                      // string (optional) - New code
  "description": "Allows reading any account (updated)",  // string (optional) - New description
  "tags": ["account", "read"],                     // string[] (optional) - Replacement tags
  "meta": {                                        // object (optional) - New metadata
    "schema_version": "1.0"                          // string (optional) - Schema version
  }
}
```

### Response

Updated `Permission` object.

---

## Delete Permission

`POST /permissions/delete`

Deletes a permission by ID.

### Request Body

```json
{
  "id": "660e8400-e29b-41d4-a716-446655440001"    // UUID (required) - Permission ID
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
