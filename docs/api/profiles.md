# Profile API

Profiles are the workspace-scoped identity for a person, distinct from the system-wide [Account](accounts.md). Each person has exactly one profile per workspace, and memberships reference profiles to grant access (see [Membership API](memberships.md)). The profile `email` is unique within a workspace (case-insensitive), so a profile can be described by either its `id` or its `email`. The profile surface is workspace-facing: responses contain persona data and the workspace-facing `email`, but never expose the account-level `account_id` or other account identity.

**All endpoints require** `Authorization: Bearer <token>`.

All endpoints are RPC-style `POST` calls, workspace-scoped (the workspace is resolved from the authenticated token), and respond with the standard `{ success, status, data }` envelope (see [Response Envelope](../response-envelope.md)).

---

## Profile Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Profile identifier |
| `workspace_id` | UUID | Workspace the profile belongs to |
| `email` | string | Workspace-facing contact email (decoupled from the account email); unique per workspace (case-insensitive) |
| `name` | string | Persona name |
| `description` | string? | Optional description |
| `display_name` | string? | Display name |
| `job_title` | string? | Job title |
| `timezone` | string? | IANA timezone identifier |
| `avatar_url` | string? | Avatar image URL |
| `version` | integer | Optimistic concurrency version |
| `tags` | string[] | Categorization tags |
| `meta` | object | Extensible metadata (`schema_version` required) |
| `created_at` | RFC 3339 | Creation timestamp |
| `updated_at` | RFC 3339? | Last update timestamp (`null` if never updated) |

---

## Describe Profile

`POST /profiles/describe`

Retrieves a profile by `id` or `email` within the caller's workspace. Exactly one of `id` or `email` is required; when both are supplied, `id` takes precedence.

### Request Body — by ID

```json
{
  "id": "aa0e8400-e29b-41d4-a716-446655440005"    // UUID (required*) - Profile ID
}
```

### Request Body — by Email

```json
{
  "email": "ada@workspace.example.com"            // string (required*) - Workspace-facing profile email
}
```

\* Exactly one of `id` or `email` is required.

### Response

Returns the full `Profile` object. Profile responses contain workspace-facing persona data and the workspace-facing `email`; account-level identity (`account_id`) is never exposed on this surface.

```json
{
  "success": true,
  "status": 200,
  "data": {
    "id": "aa0e8400-e29b-41d4-a716-446655440005",           // UUID - Profile identifier
    "workspace_id": "550e8400-e29b-41d4-a716-446655440000", // UUID - Workspace the profile belongs to
    "email": "ada@workspace.example.com",                    // string - Workspace-facing contact email
    "name": "Ada Lovelace",                                  // string - Persona name
    "description": "Analytical engine lead",                 // string? - Optional description
    "display_name": "Ada",                                   // string? - Display name
    "job_title": "Principal",                                // string? - Job title
    "timezone": "Europe/London",                             // string? - IANA timezone
    "avatar_url": null,                                      // string? - Avatar image URL
    "version": 0,                                            // integer - Optimistic concurrency version
    "tags": [],                                              // string[] - Categorization tags
    "meta": {                                                // object - Extensible metadata
      "schema_version": "1.0"                                  // string - Metadata schema version
    },
    "created_at": "2024-01-15T10:30:00Z",                    // RFC 3339 - Creation timestamp
    "updated_at": null                                       // RFC 3339? - Last update timestamp
  }
}
```

---

## List Profiles

`POST /profiles/list`

Lists profiles within a workspace. The filter supports `email` (among other profile fields) for case-insensitive matching.

### Request Body

```json
{
  "filter": {                                  // object? (optional) - Profile filters (null for no filter)
    "email": "ada@workspace.example.com"         // string? (optional) - Filter by workspace-facing email
  },
  "options": {                                 // object (optional) - Pagination options
    "limit": 50,                                 // integer (optional) - Page size
    "offset": 0                                  // integer (optional) - Page offset
  }
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "profiles": [ ... ],                       // Profile[] - Matching profiles (each a full Profile object)
    "metadata": {                              // object - Pagination metadata
      "count": 1,                                // integer - Profiles in the current page
      "limit": 50,                               // integer - Page size
      "offset": 0                                // integer - Current offset
    }
  }
}
```

---

## Update Profile

`POST /profiles/update`

Updates profile fields. All fields except `id` are optional (patch semantics); `name` must be non-empty when supplied. `email` must remain unique within the workspace (case-insensitive).

### Request Body

```json
{
  "id": "aa0e8400-e29b-41d4-a716-446655440005",           // UUID (required) - Profile ID
  "email": "ada@workspace.example.com",                    // string (optional) - Workspace-facing contact email
  "name": "Ada Lovelace",                                  // string (optional) - Name (non-empty when supplied)
  "description": "Analytical engine lead",                 // string (optional) - Optional description
  "display_name": "Ada",                                   // string (optional) - Display name
  "job_title": "Principal",                                // string (optional) - Job title
  "timezone": "Europe/London",                             // string (optional) - IANA timezone
  "avatar_url": null,                                      // string? (optional) - Avatar image URL
  "tags": [],                                              // string[] (optional) - Replacement tags
  "meta": {                                                // object (optional) - New metadata
    "schema_version": "1.0"                                  // string (optional) - Metadata schema version
  }
}
```

### Response

Returns the updated `Profile` object (same shape as [Describe Profile](#describe-profile)).

---

## Delete Profile

`POST /profiles/delete`

Deletes a profile by ID. Deletion is blocked while the profile is still referenced by memberships.

### Request Body

```json
{
  "id": "aa0e8400-e29b-41d4-a716-446655440005"    // UUID (required) - Profile ID
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

---

## Errors

Errors use the standard envelope with `success: false` (see [Response Envelope](../response-envelope.md)):

| Error | Description |
|-------|-------------|
| `PROFILE_NOT_FOUND` | No profile exists in the caller's workspace for the supplied `id` or `email` |
| `PROFILE_HAS_MEMBERSHIPS` | Profile is still referenced by memberships; deletion is blocked (HTTP 400) |
| `EMAIL_CONFLICT` | The requested `email` is already in use by another profile in this workspace (HTTP 409) |
| `INVALID_PARAMS` | Neither `id` nor `email` was provided to `describe`, or `email` is malformed |
| `WORKSPACE_MISMATCH` | Profile belongs to another workspace |
| `PERMISSION_DENIED` | Caller lacks `profile:update` or `profile:delete` (generic message) |
