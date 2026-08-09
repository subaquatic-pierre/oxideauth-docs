# Workspace API

Workspaces are the top-level multi-tenancy containers. Every resource (accounts, projects, roles, permissions) belongs to a workspace.

**All endpoints require** `Authorization: Bearer <token>`.

---

## Create Workspace

`POST /workspace/create`

Creates a new workspace. The slug must be globally unique.

### Request Body

```json
{
  "name": "My Organization",                             // string (required) - Display name
  "slug": "my-org",                                      // string (required) - URL-friendly unique identifier
  "description": "Primary workspace for My Organization", // string (optional) - Optional description
  "config": {                                            // object (required) - Workspace configuration
    "schema_version": "1.0"                              // string (required) - Config schema version
  },
  "tags": ["production", "primary"],                     // string[] (required) - Categorization tags
  "meta": {                                              // object (required) - Extensible metadata
    "schema_version": "1.0"                              // string (required) - Metadata schema version
  }
}
```

### Response

Returns the created `Workspace` object:

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",     // UUID - Workspace identifier
  "name": "My Organization",                         // string - Display name
  "slug": "my-org",                                  // string - Unique slug
  "description": "Primary workspace",                // string? - Optional description
  "config": { "schema_version": "1.0" },             // object - Workspace config
  "tags": ["production", "primary"],                 // string[] - Tags
  "meta": { "schema_version": "1.0" },               // object - Metadata
  "created_at": "2024-01-15T10:30:00Z",              // RFC 3339 - Creation timestamp
  "updated_at": "2024-01-15T10:30:00Z"               // RFC 3339? - Last update timestamp
}
```

---

## Describe Workspace

`POST /workspace/describe`

Retrieves a workspace by `id` or `slug`.

### Request Body

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",     // UUID (optional*) - Workspace ID
  "slug": "my-org"                                   // string (optional*) - Workspace slug
}
```

\* Either `id` or `slug` must be provided.

### Response

Full `Workspace` object (same schema as Create response).

---

## List Workspaces

`POST /workspace/list`

Lists all workspaces with optional filtering and pagination.

### Request Body

```json
{
  "filter": {                                        // object (optional) - Filter parameters
    "tags": [],                                      // string[] (optional) - Filter by tags
    "fields": {}                                     // object (optional) - Filter by field values (`id`, `name`, `slug`, `description`)
  },
  "options": {                                       // object (optional) - Pagination options
    "limit": 10,                                     // integer (optional) - Page size
    "offset": 0,                                     // integer (optional) - Records to skip
    "order_bys": "!created_at"                       // string (optional) - Sort order (`"created_at"` for ASC, `"!created_at"` for DESC)
  }
}
```

!!! note "Filter Combination"
    `filter.tags` and `filter.fields` are combined via **AND** logic — both conditions must match for a record to be returned.

!!! tip "Empty Body"
    Sending an empty body `{}` is valid — no filters are applied and default list options are used (limit=100, newest first).

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

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",     // UUID (optional*) - Workspace ID to update
  "slug": "my-org",                                  // string (optional*) - Slug of workspace to update
  "name": "My Organization (Updated)",               // string (optional) - New display name
  "description": "Updated description",              // string (optional) - New description
  "config": { "schema_version": "1.0" },             // object (optional) - New config
  "tags": ["production", "primary"],                 // string[] (optional) - Replacement tags
  "meta": { "schema_version": "1.0" }                // object (optional) - New metadata
}
```

\* Either `id` or `slug` must be provided to identify the workspace.

### Response

Updated `Workspace` object.

---

## Delete Workspace

`POST /workspace/delete`

Deletes a workspace. **This is a destructive operation.**

### Request Body

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",     // UUID (optional*) - Workspace ID
  "slug": "my-org"                                   // string (optional*) - Workspace slug
}
```

\* Either `id` or `slug` must be provided.

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
