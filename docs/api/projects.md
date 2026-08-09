# Project API

Projects are scoped work areas within workspaces. They can represent applications, microservices, or team boundaries.

**All endpoints require** `Authorization: Bearer <token>`.

---

## Create Project

`POST /projects/create`

Creates a new project within a workspace. The name must be unique within the workspace.

### Request Body

```json
{
  "name": "Web Application",                              // string (required) - Project name (unique per workspace)
  "code": "web-app",                                      // string (optional) - Short code identifier
  "description": "Main customer-facing web application",  // string (optional) - Optional description
  "config": { "schema_version": "1.0" },                  // object (required) - Project configuration (schema_version required)
  "tags": ["frontend", "public"],                         // string[] (required) - Categorization tags
  "meta": { "schema_version": "1.0" }                     // object (required) - Metadata (schema_version required)
}
```

### Response

Returns the created `Project` object:

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",           // UUID - Project identifier
  "name": "Web Application",                              // string - Display name
  "code": "web-app",                                      // string? - Short code
  "description": "Main customer-facing web application",  // string? - Description
  "config": { "schema_version": "1.0" },                  // object - Project config
  "tags": ["frontend", "public"],                         // string[] - Categorization tags
  "meta": { "schema_version": "1.0" },                    // object - Metadata
  "created_at": "2024-01-15T10:30:00Z",                   // RFC 3339 - Creation timestamp
  "updated_at": null                                      // RFC 3339? - Last update, null if never updated
}
```

---

## Describe Project

`POST /projects/describe`

Retrieves a project by `id` or `code`.

### Request Body

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",  // UUID (optional*) - Project ID
  "code": "web-app"                              // string (optional*) - Project code
}
```

\* Either `id` or `code` must be provided.

### Response

Full `Project` object:

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",           // UUID - Project identifier
  "name": "Web Application",                              // string - Display name
  "code": "web-app",                                      // string? - Short code
  "description": "Main customer-facing web application",  // string? - Description
  "config": { "schema_version": "1.0" },                  // object - Project config
  "tags": ["frontend", "public"],                         // string[] - Categorization tags
  "meta": { "schema_version": "1.0" },                    // object - Metadata
  "created_at": "2024-01-15T10:30:00Z",                   // RFC 3339 - Creation timestamp
  "updated_at": null                                      // RFC 3339? - Last update, null if never updated
}
```

---

## List Projects

`POST /projects/list`

Lists projects within a workspace.

### Request Body

```json
{
  "filter": {                   // object (optional) - Filter (tags + fields)
    "tags": [],                 // string[] (optional) - Only include projects with all listed tags
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

### Filter Fields (`filter.fields`)

`id`, `workspace_id`, `name`, `code`, `description`, `created_by`

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

Updates project fields. All fields are optional.

### Request Body

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",  // UUID (optional*) - Project ID
  "code": "web-app",                             // string (optional*) - Current code (to identify project)
  "name": "Web Application v2",                  // string (optional) - New name
  "new_code": "web-app-v2",                      // string (optional) - Rename code
  "description": "Updated description",          // string (optional) - New description
  "config": { "schema_version": "1.0" },         // object (optional) - New config
  "tags": ["frontend", "public"],                // string[] (optional) - Replacement tags
  "meta": { "schema_version": "1.0" }            // object (optional) - New metadata
}
```

\* Either `id` or `code` must be provided.

### Response

Updated `Project` object:

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",           // UUID - Project identifier
  "name": "Web Application",                              // string - Display name
  "code": "web-app",                                      // string? - Short code
  "description": "Main customer-facing web application",  // string? - Description
  "config": { "schema_version": "1.0" },                  // object - Project config
  "tags": ["frontend", "public"],                         // string[] - Categorization tags
  "meta": { "schema_version": "1.0" },                    // object - Metadata
  "created_at": "2024-01-15T10:30:00Z",                   // RFC 3339 - Creation timestamp
  "updated_at": null                                      // RFC 3339? - Last update, null if never updated
}
```

---

## Delete Project

`POST /projects/delete`

Deletes a project by `id` or `code`.

### Request Body

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",  // UUID (optional*) - Project ID
  "code": "web-app"                              // string (optional*) - Project code
}
```

\* Either `id` or `code` must be provided.

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
