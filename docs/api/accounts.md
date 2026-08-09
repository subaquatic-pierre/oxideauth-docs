# Account API

User account management. Accounts are global identities that can belong to multiple workspaces via [memberships](memberships.md).

**All endpoints require** `Authorization: Bearer <token>`.

---

## Create Account

`POST /accounts/create`

Creates a new user account within a workspace. The email must be globally unique.

### Request Body

```json
{
  "email": "alice@example.com",                           // string (required) - Unique email address
  "password": "SecureP@ssw0rd!",                          // string (required) - Account password (hashed with Argon2 server-side)
  "name": "Alice Johnson",                                // string (required) - Display name
  "description": "Engineering team lead",                 // string (optional) - Optional description
  "avatar_url": "https://example.com/avatars/alice.png",  // string (optional) - Avatar image URL
  "tags": ["engineering", "staff"],                       // string[] (optional) - Categorization tags
  "meta": { "schema_version": "1.0" }                     // object (optional) - Metadata (schema_version required if provided)
}
```

### Response

Returns the created `Account` object:

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",           // UUID - Account identifier
  "email": "alice@example.com",                           // string - Email address
  "name": "Alice Johnson",                                // string - Display name
  "description": "Engineering team lead",                 // string? - Optional description
  "avatar_url": "https://example.com/avatars/alice.png",  // string? - Avatar URL
  "enabled": true,                                        // boolean - Whether the account is active
  "verified": true,                                       // boolean - Whether the email is verified
  "tags": ["engineering", "staff"],                       // string[] - Categorization tags
  "meta": { "schema_version": "1.0" },                    // object - Metadata
  "created_at": "2024-01-15T10:30:00Z",                   // RFC 3339 - Creation timestamp
  "updated_at": null                                      // RFC 3339? - Last update, null if never updated
}
```

---

## Describe Account

`POST /accounts/describe`

Retrieves an account by `id` or `email`.

### Request Body

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",  // UUID (optional*) - Account ID
  "email": "alice@example.com"                   // string (optional*) - Account email
}
```

\* Either `id` or `email` must be provided.

### Response

Full `Account` object:

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",           // UUID - Account identifier
  "email": "alice@example.com",                           // string - Email address
  "name": "Alice Johnson",                                // string - Display name
  "description": "Engineering team lead",                 // string? - Optional description
  "avatar_url": "https://example.com/avatars/alice.png",  // string? - Avatar URL
  "enabled": true,                                        // boolean - Whether the account is active
  "verified": true,                                       // boolean - Whether the email is verified
  "tags": ["engineering", "staff"],                       // string[] - Categorization tags
  "meta": { "schema_version": "1.0" },                    // object - Metadata
  "created_at": "2024-01-15T10:30:00Z",                   // RFC 3339 - Creation timestamp
  "updated_at": null                                      // RFC 3339? - Last update, null if never updated
}
```

---

## List Accounts

`POST /accounts/list`

Lists accounts in a workspace with optional filtering and pagination.

### Request Body

```json
{
  "filter": {                   // object (optional) - Filter parameters
    "tags": ["engineering"],    // string[] (optional) - Only include accounts with all listed tags
    "fields": {}                // object (optional) - Field filters (see Filter Fields below)
  },
  "options": {                  // object (optional) - Pagination options
    "limit": 10,                // integer (optional) - Maximum number of items to return
    "offset": 0,                // integer (optional) - Number of items to skip
    "order_bys": "!created_at"  // string (optional) - Sort order; prefix `!` for descending
  }
}
```

### Filter Fields (`filter.fields`)

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Account ID |
| `email` | string | Email address |
| `name` | string | Display name |
| `description` | string | Description text |
| `avatar_url` | string | Avatar URL |
| `verified` | boolean | Email verified |
| `enabled` | boolean | Account active |
| `created_by` | UUID | Creator account ID |
| `created_at` | datetime | Creation time |
| `updated_by` | UUID | Last updater account ID |
| `updated_at` | datetime | Last update time |

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
    "accounts": [ ... ],
    "metadata": {
      "total": 15,
      "count": 10,
      "offset": 0,
      "limit": 10,
      "order_bys": ["!created_at"]
    }
  }
}
```

---

## Update Account

`POST /accounts/update`

Updates account fields. All fields are optional.

### Request Body

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",           // UUID (optional*) - Account ID
  "email": "alice@example.com",                           // string (optional*) - Current email (to identify account)
  "name": "Alice Johnson-Smith",                          // string (optional) - New display name
  "description": "Senior Engineering Lead",               // string (optional) - New description
  "avatar_url": "https://example.com/avatars/alice.png",  // string (optional) - New avatar URL
  "enabled": true,                                        // boolean (optional) - Enable/disable account
  "verified": true,                                       // boolean (optional) - Verify/unverify account
  "tags": ["engineering", "staff", "leadership"],         // string[] (optional) - Replacement tags
  "meta": { "schema_version": "1.0" }                     // object (optional) - New metadata
}
```

\* Either `id` or `email` must be provided to identify the account.

### Response

Updated `Account` object:

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",           // UUID - Account identifier
  "email": "alice@example.com",                           // string - Email address
  "name": "Alice Johnson",                                // string - Display name
  "description": "Engineering team lead",                 // string? - Optional description
  "avatar_url": "https://example.com/avatars/alice.png",  // string? - Avatar URL
  "enabled": true,                                        // boolean - Whether the account is active
  "verified": true,                                       // boolean - Whether the email is verified
  "tags": ["engineering", "staff"],                       // string[] - Categorization tags
  "meta": { "schema_version": "1.0" },                    // object - Metadata
  "created_at": "2024-01-15T10:30:00Z",                   // RFC 3339 - Creation timestamp
  "updated_at": null                                      // RFC 3339? - Last update, null if never updated
}
```

---

## Delete Account

`POST /accounts/delete`

Deletes an account by `id` or `email`.

### Request Body

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",  // UUID (optional*) - Account ID
  "email": "alice@example.com"                   // string (optional*) - Account email
}
```

\* Either `id` or `email` must be provided.

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000"
  }
}
```
