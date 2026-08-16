# Policy Engine

Policies are **first-class, workspace-scoped authorization rules** in the AWS-IAM style: each rule declares an `effect` (`allow` or `deny`), a `principal`, a set of `actions`, a `resource`, and an optional `constraint`. Policies are attached to [roles](roles.md) and [memberships](membership.md) and *grant* as well as *restrict* access: an `allow` policy grants actions, while a `deny` policy overrides any grant.

Policy CRUD is **workspace-admin only**. See the [Policy API reference](../api/policies.md) for the full request/response shapes.

## Policy Document

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string? | no | Unique per workspace when present |
| `effect` | string | yes | `"allow"` or `"deny"` |
| `principal_id` | UUID? | no | Principal the rule applies to; defaults to the attachment target |
| `actions` | string[] | yes | Non-empty; `"resource:action"` pairs; `"*"` allowed |
| `resource` | string | yes | `"self"`, `"<uuid>"`, or `"*"` |
| `constraint` | string? | no | Constraint DSL expression (see below) |

```jsonc
{
  "effect": "allow",                             // string (required) - "allow" | "deny"
  "actions": ["profile:update"],                 // string[] (required) - "resource:action"; "*" allowed
  "resource": "self",                            // string (required) - "self" | "<uuid>" | "*"
  "constraint": "profile.account.id === user.id" // string? (optional) - Constraint DSL expression
}
```

## Evaluation Semantics

- **Deny overrides allow**: an explicit `deny` for an action always wins, even when an `allow` also matches.
- **Default deny**: anything not explicitly allowed is denied.

```text
deny policy matches  → deny
allow policy matches → allow
nothing matches      → deny (default)
```

## Attachment Model

Policies attach to **roles** (bulk) and **memberships** (per-member) via `policy_ids`:

- Role create/update DTOs accept `policy_ids`; role describe responses resolve them into `policies: Policy[]`.
- Membership create/update DTOs accept `policy_ids`; membership describe responses resolve them into `policies: Policy[]`.
- `policy_ids` on update replaces links (set semantics).

A user's effective policy set is the **deduplicated union** of the policies attached to all of their roles and all of their memberships.

## Workspace Scoping

Policies are **workspace-scoped**: each policy belongs to exactly one workspace and is resolved from the authenticated token. **Project-scoped policies are not yet supported.**

## Constraint DSL

Constraints refine a policy at evaluation time. The grammar:

```text
constraint       := attribute_path comparator operand
comparator       := "===" | "!=="
operand          := attribute_path | literal
attribute_path   := ident ("." ident)*
```

- The **left** attribute path resolves against the **target resource**.
- The **right** operand resolves against the **request context**.
- `user.id` is a reserved path equal to the authenticated account id.

**Worked example** — `profile.account.id === user.id`: permits the action only when the target resource's `account.id` equals the requesting user's id.

## O(1) Runtime Lookup

Policies are compiled to a runtime key for O(1) lookup:

```text
effect | sort(actions).join(",") | resource | (constraint ?? "")
```

Identical runtime keys are rejected at create time (`409 Duplicate runtime key`), so each key maps to a single policy within a workspace.

## Default Self-Mutation Policies

New workspaces ship with default `allow` policies for self-service mutations, for example:

- `profile:update` on `self` with constraint `profile.account.id === user.id` — members may update their own profile.
