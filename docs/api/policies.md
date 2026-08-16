# Policy API

Policies are workspace-scoped authorization rules in the AWS-IAM style: each rule declares an `effect` (`allow` or `deny`), a `principal`, a set of `actions`, a `resource`, and an optional `constraint`. Policies are attached to [roles](roles.md) and [memberships](memberships.md) and constrain what those role/membership grants may actually do. Policy CRUD is **workspace-admin only**. Project-scoped policies are not yet supported.

**All endpoints require** `Authorization: Bearer <token>`.

All endpoints are RPC-style `POST` calls, workspace-scoped (the workspace is resolved from the authenticated token), and respond with the standard `{ success, status, data }` envelope (see [Response Envelope](../response-envelope.md)).

---

## Policy Document

A policy is a JSON document. Only `effect`, `actions`, and `resource` are required:

```jsonc
{
  "name": "self-update",                       // string? (optional) - Unique per workspace
  "effect": "allow",                           // string (required) - "allow" | "deny"
  "principal_id": null,                        // UUID? (optional) - Defaults to the attachment target
  "actions": ["profile:update"],               // string[] (required, non-empty) - "resource:action"; "*" allowed
  "resource": "self",                          // string (required) - "self" | "<uuid>" | "*"
  "constraint": "profile.account.id === user.id", // string? (optional) - Constraint DSL expression
  "description": "string",                     // string? (optional) - Description
  "tags": [],                                  // string[] (optional) - Categorization tags
  "meta": {}                                   // object (optional) - Extensible metadata
}
```

### Policy Document Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string? | no | Unique per workspace when present |
| `effect` | string | yes | `"allow"` or `"deny"` |
| `principal_id` | UUID? | no | Principal the rule applies to; defaults to the attachment target |
| `actions` | string[] | yes | Non-empty; `"resource:action"` pairs; `"*"` allowed |
| `resource` | string | yes | `"self"`, `"<uuid>"`, or `"*"` |
| `constraint` | string? | no | Constraint DSL expression (see below) |
| `description` | string? | no | Free-form description |
| `tags` | string[] | no | Categorization tags |
| `meta` | object | no | Extensible metadata |

---

## Constraint DSL

Constraints refine a policy at evaluation time. The grammar is:

```text
constraint       := attribute_path comparator operand
comparator       := "===" | "!=="
operand          := attribute_path | literal
attribute_path   := ident ("." ident)*
```

- The left attribute path resolves against the **target resource**.
- The right operand resolves against the **request context**.
- `user.id` is a reserved path equal to the authenticated account id.

Example constraint: `profile.account.id === user.id` — permits the action only when the target resource's `account.id` equals the requesting user's id.

The runtime key used for O(1) policy lookup is:

```text
effect | sort(actions).join(",") | resource | (constraint ?? "")
```

---

## Describe Policy

`POST /policies/describe`

Retrieves a policy by ID within the caller's workspace.

### Request Body

```json
{
  "id": "cc0e8400-e29b-41d4-a716-446655440006"    // UUID (required) - Policy ID
}
```

### Response

Returns the full `Policy` object:

```json
{
  "success": true,
  "status": 200,
  "data": {
    "id": "cc0e8400-e29b-41d4-a716-446655440006",           // UUID - Policy identifier
    "workspace_id": "550e8400-e29b-41d4-a716-446655440000", // UUID - Workspace the policy belongs to
    "name": "self-update",                                   // string? - Name (unique per workspace)
    "effect": "allow",                                       // string - "allow" or "deny"
    "principal_id": null,                                    // UUID? - Principal; defaults to the attachment target
    "actions": ["profile:update", "membership:update"],      // string[] - Permitted actions
    "resource": "self",                                      // string - "self", "<uuid>", or "*"
    "constraint": "profile.account.id === user.id",          // string? - Constraint DSL expression
    "description": "Members may update their own profile/membership", // string? - Description
    "tags": [],                                              // string[] - Categorization tags
    "meta": {},                                              // object - Extensible metadata
    "created_at": "2024-01-15T10:30:00Z",                    // RFC 3339 - Creation timestamp
    "updated_at": null                                       // RFC 3339? - Last update timestamp
  }
}
```

---

## Create Policy

`POST /policies/create`

Creates a policy within the caller's workspace. Policy creation is workspace-admin only.

### Request Body

The request body is the full [policy document](#policy-document) (all fields except `id`):

```json
{
  "name": "self-update",                            // string? (optional) - Unique per workspace
  "effect": "allow",                                // string (required) - "allow" or "deny"
  "principal_id": null,                             // UUID? (optional) - Defaults to the attachment target
  "actions": ["profile:update", "membership:update"], // string[] (required) - Permitted actions
  "resource": "self",                               // string (required) - "self", "<uuid>", or "*"
  "constraint": "profile.account.id === user.id",   // string? (optional) - Constraint DSL expression
  "description": "Members may update their own profile/membership", // string? (optional)
  "tags": [],                                       // string[] (optional) - Categorization tags
  "meta": {}                                        // object (optional) - Extensible metadata
}
```

### Response

Returns the created `Policy` object (same shape as [Describe Policy](#describe-policy)).

---

## List Policies

`POST /policies/list`

Lists policies within a workspace.

### Request Body

```json
{
  "filter": {                                      // object (optional) - Filter parameters
    "effect": "allow",                               // string? (optional) - "allow" or "deny"
    "resource": "self"                               // string? (optional) - "self", "<uuid>", or "*"
  },
  "options": {                                     // object (optional) - Pagination options
    "limit": 50,                                     // integer (optional) - Page size
    "offset": 0                                      // integer (optional) - Page offset
  }
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "policies": [ ... ],                           // Policy[] - Matching policies (each a full Policy object)
    "metadata": {                                  // object - Pagination metadata
      "count": 1,                                    // integer - Policies in the current page
      "limit": 50,                                   // integer - Page size
      "offset": 0                                    // integer - Current offset
    }
  }
}
```

---

## Update Policy

`POST /policies/update`

Updates policy fields. All fields except `id` are optional (patch semantics). Policy updates are workspace-admin only.

### Request Body

```json
{
  "id": "cc0e8400-e29b-41d4-a716-446655440006",           // UUID (required) - Policy ID
  "effect": "deny",                                         // string (optional) - "allow" or "deny"
  "actions": ["profile:update"],                            // string[] (optional) - Replacement actions
  "constraint": "profile.account.id !== user.id"            // string? (optional) - Replacement constraint
}
```

### Response

Returns the updated `Policy` object (same shape as [Describe Policy](#describe-policy)).

---

## Delete Policy

`POST /policies/delete`

Deletes a policy by ID. Policy deletion is workspace-admin only.

### Request Body

```json
{
  "id": "cc0e8400-e29b-41d4-a716-446655440006"    // UUID (required) - Policy ID
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "id": "cc0e8400-e29b-41d4-a716-446655440006"
  }
}
```

---

## Attachment

Policies are attached to roles and memberships inline, via their DTOs:

- `RoleCreateReq` / `RoleUpdateReq` accept `policy_ids` (`UUID[]` on create, `UUID[]?` on update); `RoleDescribeRes` includes resolved `policies: Policy[]`.
- `MembershipCreateReq` / `MembershipUpdateReq` accept `policy_ids`; `MembershipDescribeRes` includes resolved `policies: Policy[]` and `profile_id`.
- `policy_ids` on update replaces links (set semantics).

Effective policies for a user are the deduplicated union of role-attached and membership-attached policies. Evaluation precedence: an explicit `deny` overrides `allow`; anything not allowed is denied by default.

---

## Errors

Errors use the standard envelope with `success: false` (see [Response Envelope](../response-envelope.md)):

| Error | HTTP | Description |
|-------|------|-------------|
| Non-admin mutation | 403 | Policy create/update/delete by a non-admin caller (generic message) |
| Invalid constraint | 400 | Malformed constraint DSL; the response names the constraint |
| Duplicate runtime key | 409 | A policy with the same runtime key already exists in the workspace |
| Cross-workspace reference | 403 | Referenced policy belongs to another workspace |
