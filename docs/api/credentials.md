# Credential API

Authentication credential management. Credentials link accounts to authentication providers.

!!! note "No Create Endpoint"
    Credentials are created implicitly during account registration or OAuth flows. This API provides describe, list, update, and delete operations.

**All endpoints require** `Authorization: Bearer <token>`.

---

## Credential Types

### Kind

| Kind | Description |
|------|-------------|
| `password` | Local password authentication (Argon2 hashed) |
| `oauth` | OAuth2 provider authentication |
| `sso` | Single Sign-On provider |
| `api_key` | API key authentication |

### Provider

| Provider | Description |
|----------|-------------|
| `local` | Local password |
| `google` | Google OAuth2 |
| `github` | GitHub OAuth |

### Status

| Status | Description |
|--------|-------------|
| `active` | Credential is valid and usable |
| `revoked` | Credential has been revoked |
| `pending` | Awaiting verification (e.g., email not confirmed) |

---

## Describe Credential

`POST /credentials/describe`

Retrieves a credential by ID.

### Request Body

```json
{
  "id": "bb0e8400-e29b-41d4-a716-446655440006",            // UUID (required) - Credential ID
  "account_id": "880e8400-e29b-41d4-a716-446655440003",    // UUID (required) - Owning account
  "provider_id": "google-12345",                             // string (optional) - External provider ID
  "email": "user@example.com"                                // string (optional) - Associated email
}
```

### Response

Returns the `Credential` object:

```json
{
  "id": "bb0e8400-e29b-41d4-a716-446655440006",            // UUID - Credential identifier
  "account_id": "880e8400-e29b-41d4-a716-446655440003",    // UUID - Owning account
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",  // UUID - Workspace
  "kind": "password",                                        // string - "password", "oauth", "sso", or "api_key"
  "provider": "local",                                       // string - "local", "google", or "github"
  "status": "active",                                        // string - "active", "revoked", or "pending"
  "provider_id": "google-12345",                             // string? - External provider identifier
  "email": "user@example.com",                               // string? - Associated email
  "last_used_at": "2024-01-15T10:30:00Z",                    // RFC 3339? - Last authentication timestamp
  "tags": ["password"],                                      // string[] - Tags
  "meta": {                                                  // object - Metadata
    "schema_version": "1.0"                                    // string - Schema version
  },
  "created_at": "2024-01-15T10:30:00Z",                      // RFC 3339 - Creation timestamp
  "updated_at": "2024-01-15T10:30:00Z"                       // RFC 3339? - Last update timestamp
}
```

---

## List Credentials

`POST /credentials/list`

Lists credentials within a workspace.

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

`id`, `account_id`, `workspace_id`, `kind`, `provider`, `status`, `provider_id`, `email`

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "credentials": [ ... ],
    "metadata": { "total": 4, "count": 4, ... }
  }
}
```

---

## Update Credential

`POST /credentials/update`

Updates a credential's fields. All fields except `id` and `account_id` are optional.

### Request Body

```json
{
  "id": "bb0e8400-e29b-41d4-a716-446655440006",             // UUID (required) - Credential ID
  "account_id": "880e8400-e29b-41d4-a716-446655440003",     // UUID (required) - Owning account
  "kind": "password",                                        // string (optional) - "password", "oauth", "sso", or "api_key"
  "provider": "local",                                       // string (optional) - "local", "google", or "github"
  "status": "active",                                        // string (optional) - "active", "revoked", or "pending"
  "provider_id": "google-12345",                             // string (optional) - External provider ID
  "email": "user@example.com",                               // string (optional) - Associated email
  "new_provider_id": "google-67890",                         // string (optional) - Replace external provider ID
  "new_email": "new@example.com",                            // string (optional) - Replace associated email
  "secret": "s3cret",                                        // string (optional) - New password/secret
  "last_used_at": "2024-01-15T10:30:00Z",                    // RFC 3339 (optional) - Last usage timestamp
  "tags": ["password"],                                      // string[] (optional) - Replacement tags
  "meta": {                                                  // object (optional) - New metadata
    "schema_version": "1.0"                                    // string (optional) - Schema version
  }
}
```

### Response

Updated `Credential` object.

---

## Delete Credential

`POST /credentials/delete`

Deletes a credential by ID.

### Request Body

```json
{
  "id": "bb0e8400-e29b-41d4-a716-446655440006",            // UUID (required) - Credential ID
  "account_id": "880e8400-e29b-41d4-a716-446655440003",    // UUID (required) - Owning account
  "provider_id": "google-12345",                             // string (optional) - External provider ID
  "email": "user@example.com"                                // string (optional) - Associated email
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "id": "bb0e8400-e29b-41d4-a716-446655440006"
  }
}
```
