# Identity Model: Accounts, Profiles & Memberships

OxideAuth splits identity into three related entities: the **Account** is the system-wide identity for a person, the **Profile** is the workspace-scoped identity for that person, and the **Membership** is the authority record that links the two together inside a workspace.

## The Three-Way Split

| Entity | Kind | Meaning |
|--------|------|---------|
| **Account** | System-wide identity | One identity per person, keyed by a unique email; opaque outside the system domain. |
| **Profile** | Workspace identity | The persona a workspace sees and edits; one per account per workspace; carries a workspace-facing email. |
| **Membership** | Authority | Grants access in a workspace; references a profile and carries role, status, and scope. |

### Account

An **Account** is the system-wide identity for a person. It is keyed by a unique email address and carries the authentication, verification, and global enablement state of the identity (for example, whether the identity is verified and whether it is enabled). Accounts are opaque outside the system domain: no workspace-facing surface exposes an account's email address or account-level identifier.

Key fields: `id`, `email`, `name`, `verified`, `enabled`, `tags`, `meta`, audit.

### Profile

A **Profile** is the workspace-scoped identity for a person. There is exactly one profile per account per workspace, enforced by a unique index on `(account_id, workspace_id)`. A profile carries the persona fields a workspace sees and edits: `email`, `name`, `description`, `display_name`, `job_title`, `timezone`, and `avatar_url`.

Key fields: `id`, `account_id`, `workspace_id`, `email`, `name`, `description`, `display_name`, `job_title`, `timezone`, `avatar_url`, `version`, `tags`, `meta`, audit.

The profile's response shape exposes the persona fields and the workspace-facing `email` (plus `id`, `workspace_id`, `version`, `tags`, `meta`, and timestamps). It never exposes the `account_id` or other account-level identity.

### Membership

A **Membership** is the authority record that grants a person access inside a workspace. It references the profile (via `profile_id`), the workspace, and optionally a project, and it carries the role assignments, the membership `status`, and the `scope` (`workspace` or `project`). A membership may also carry directly attached policies (`policy_ids`).

Key fields: `id`, `account_id`, `workspace_id`, `profile_id?`, `project_id?`, `scope`, `status`, `tags`, `meta`, audit.

`membership.profile_id` is nullable: legacy memberships created through the `account_id` path have no profile until it is resolved.

## Privacy Rules

- Workspace-facing surfaces never expose the account-level identity (`account_id`) or the account email.
- Profiles expose a workspace-facing `email` that is decoupled from the account email.
- Membership responses retain the `account_id` (a UUID) but never include the account email.
- System administrators retain account read and list access outside the workspace-facing surfaces.

## Onboarding by Email

Members are onboarded by email:

1. **Provide the email**: `email` is always required and is validated/normalized.
2. **Optionally link an existing account**: `account_id` is optional. When provided, the account is resolved by id and the supplied email becomes the profile email. When omitted, the email is resolved to an existing account or a new account is created.
3. **Optionally supply persona details**: `profile` is optional and applies persona fields only when a new profile is created.
4. **Create the profile**: a profile is created (or resolved) for the account in the workspace (one profile per account per workspace).
5. **Create the membership**: the membership is created referencing the profile, with its roles, status, scope, and optional directly attached policies.

The response carries the `profile_id` of the created or resolved profile and never the account email.

## Related

- [Memberships](membership.md) — the authority record in detail
- [RBAC & Permissions](permissions.md) — roles and permissions
- [Policy Engine](../architecture/policies.md) — workspace-scoped authorization rules
