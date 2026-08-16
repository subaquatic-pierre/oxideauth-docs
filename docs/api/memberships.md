# Membership API

Memberships link [accounts](accounts.md) to workspaces or projects, assigning [roles](roles.md) and [policies](policies.md) that grant access. Each membership references a [profile](../concepts/identity-model.md) (the workspace-facing identity of the account).

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

Creates a membership linking an account to a workspace or project. `email` is always required and is validated/normalized. `account_id` is optional: when omitted, the API resolves the email to an existing account or creates a new one; when provided, the account is resolved by id and the supplied email becomes the profile email. `profile` is optional and supplies persona details only when a new profile is created.

### Request Body

```json
{
  "email": "member@example.com",                            // string (required) - Onboarding email (validated/normalized)
  "account_id": "880e8400-e29b-41d4-a716-446655440003",    // UUID (optional) - Existing account to link; when omitted, account is resolved/created by email
  "profile": {                                              // object (optional) - Persona details applied only when a new profile is created
    "name": "Member Name",                                    // string (optional) - Persona name
    "description": "...",                                     // string? (optional) - Optional description
    "display_name": "...",                                    // string? (optional) - Display name
    "job_title": "...",                                       // string? (optional) - Job title
    "timezone": "...",                                        // string? (optional) - IANA timezone
    "avatar_url": "...",                                      // string? (optional) - Avatar image URL
    "tags": [],                                               // string[] (optional) - Categorization tags
    "meta": { "schema_version": "1.0" }                       // object (optional) - Extensible metadata
  },
  "scope": "workspace",                                     // string (required) - "workspace" or "project"
  "status": "active",                                       // string (required) - "invited", "active", or "suspended"
  "project_id": "990e8400-e29b-41d4-a716-446655440004",     // UUID (optional*) - Project ID (required if scope is "project")
  "role_ids": ["770e8400-e29b-41d4-a716-446655440002"],     // UUID[] (required) - Roles to assign
  "policy_ids": ["cc0e8400-e29b-41d4-a716-446655440006"],   // UUID[] (required) - Policies to attach
  "tags": ["member"],                                       // string[] (required) - Categorization tags
  "meta": {                                                 // object (required) - Metadata (schema_version required)
    "schema_version": "1.0"                                   // string (required) - Metadata schema version
  }
}
```

\* `email` is always required and is validated/normalized. `account_id` is optional; when provided, the account is resolved by id and the supplied email becomes the profile email. `profile` is optional and applies persona details only when a new profile is created. `project_id` is required when `scope` is `"project"`.

### Project-Scoped Example

```json
{
  "email": "member@example.com",
  "scope": "project",
  "status": "active",
  "project_id": "990e8400-e29b-41d4-a716-446655440004",
  "role_ids": ["770e8400-e29b-41d4-a716-446655440002"],
  "policy_ids": ["cc0e8400-e29b-41d4-a716-446655440006"],
  "tags": ["contributor"],
  "meta": { "schema_version": "1.0" }
}
```

### New-Profile Example

When the caller wants to supply persona details for the newly created profile, include the optional `profile` object. These fields are applied only when a new profile is created for the membership.

```json
{
  "email": "member@example.com",
  "profile": {
    "name": "Member Name",
    "description": "Engineering team member",
    "display_name": "Member",
    "job_title": "Engineer",
    "timezone": "UTC",
    "avatar_url": null,
    "tags": ["engineering"],
    "meta": { "schema_version": "1.0" }
  },
  "scope": "workspace",
  "role_ids": ["770e8400-e29b-41d4-a716-446655440002"],
  "policy_ids": ["cc0e8400-e29b-41d4-a716-446655440006"],
  "tags": ["member"],
  "meta": { "schema_version": "1.0" }
}
```

### Response

Returns the created `Membership` object with nested roles and resolved policies:

```json
{
  "id": "aa0e8400-e29b-41d4-a716-446655440005",              // UUID - Membership identifier
  "account_id": "880e8400-e29b-41d4-a716-446655440003",      // UUID - Linked account (opaque outside the system)
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",    // UUID - Workspace
  "profile_id": "bb0e8400-e29b-41d4-a716-446655440007",       // UUID? - Linked workspace profile (workspace-visible identity anchor)
  "project_id": "990e8400-e29b-41d4-a716-446655440004",      // UUID? - Project (if project-scoped)
  "scope": "workspace",                                       // string - "workspace" or "project"
  "status": "active",                                         // string - "invited", "active", or "suspended"
  "roles": [                                                  // Role[] - Assigned roles with permissions
    {
      "id": "770e8400-e29b-41d4-a716-446655440002"             // UUID - Role identifier
    }
  ],
  "policies": [                                               // Policy[] - Resolved attached policy objects
    {
      "id": "cc0e8400-e29b-41d4-a716-446655440006",            // UUID - Policy identifier
      "name": "self-update",                                   // string? - Policy name (unique per workspace)
      "effect": "allow",                                       // string - "allow" or "deny"
      "actions": ["profile:update"],                           // string[] - Actions the policy allows or denies
      "resource": "self",                                      // string - "self", "<uuid>", or "*"
      "constraint": "profile.account.id === user.id"           // string? - Constraint DSL expression
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

!!! note "Privacy"
    Membership responses never include the account email. Each account is keyed by a unique email, but that identity stays opaque outside the system: a workspace sees the linked [profile](../concepts/identity-model.md) (via `profile_id`) and the account id as a UUID only. The profile itself exposes a workspace-facing `email` that may differ from the account email. See [Identity Model](../concepts/identity-model.md) for the Account / Profile / Membership split.

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

Full `Membership` object with nested roles and resolved policies.

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
| `profile_id` | UUID | Profile ID |
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
  "role_ids": ["770e8400-e29b-41d4-a716-446655440002"],    // UUID[] (optional) - Replaces assigned roles
  "policy_ids": ["cc0e8400-e29b-41d4-a716-446655440006"],  // UUID[] (optional) - Replaces attached policies
  "tags": ["member", "suspended"],                         // string[] (optional) - Replacement tags
  "meta": {                                                // object (optional) - New metadata
    "schema_version": "1.0"                                  // string (optional) - Schema version
  }
}
```

### Response

Updated `Membership` object with nested roles and resolved policies.

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
