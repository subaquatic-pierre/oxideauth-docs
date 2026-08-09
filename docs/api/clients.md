# Clients API

Client registration and management for external microservices that integrate with OxideAuth. Clients are workspace-scoped entities that can validate user tokens and receive push updates when authorization state changes.

!!! note "Not OAuth2/OIDC Clients"
    The **Clients** resource is for registering external microservices that need to validate user tokens and receive push notifications. This is distinct from OAuth2 or OIDC clients, which would be a separate concept if introduced in the future.

**All endpoints require** `Authorization: Bearer <token>`.

---

## Create Client

`POST /clients/create`

Creates a new client within a workspace. The client secret is returned once — store it securely, as it cannot be retrieved later.

### Request Body

```json
{
  "name": "Payment Service",                             // string (required) - Human-readable name for the client
  "endpoint": "https://payments.example.com/oxideauth/updates",   // string (optional) - Update endpoint URL that OxideAuth calls to push cache invalidation events
  "description": "Handles payment processing",           // string (optional) - Optional description
  "tags": ["payments", "production"],                    // string[] (optional) - Categorization tags
  "meta": {                                              // object (optional) - Extensible metadata
    "schema_version": "1.0"                              // string (required) - Metadata schema version
  }
}
```

### Response

Returns the created Client object. The `secret` field is **only returned on creation and regeneration** — it is never included in describe or list responses.

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",     // UUID - Client identifier
  "workspace": {                                     // Workspace - Embedded workspace object
    "id": "550e8400-e29b-41d4-a716-446655440000",   // UUID - Workspace identifier
    "name": "My Organization",                       // string - Workspace name
    "slug": "my-org",                                // string - Workspace slug
    "description": "Primary workspace",              // string? - Workspace description
    "config": {},                                    // object - Workspace configuration
    "tags": ["production", "primary"],               // string[] - Workspace tags
    "meta": {},                                      // object - Workspace metadata
    "created_at": "2024-01-15T10:30:00Z",            // RFC 3339 - Workspace creation timestamp
    "updated_at": "2024-01-15T10:30:00Z"             // RFC 3339? - Workspace last update timestamp
  },
  "name": "Payment Service",                         // string - Client name
  "secret": "oxauth_secret_abc123",                  // string - Plaintext secret (only returned once — store immediately)
  "endpoint": "https://payments.example.com/oxideauth/updates",   // string? - Registered update endpoint URL
  "description": "Handles payment processing",       // string? - Description
  "tags": ["payments", "production"],                // string[] - Tags
  "meta": { "schema_version": "1.0" },               // object - Metadata
  "created_at": "2024-01-15T10:30:00Z"               // RFC 3339 - Creation timestamp
}
```

!!! danger "Secret Storage"
    The `secret` field appears only in the create response. There is no way to retrieve a lost secret — you must regenerate it (see [Regenerate Client Secret](#regenerate-client-secret)).

---

## Describe Client

`POST /clients/describe`

Retrieves a client by ID within a workspace.

### Request Body

```json
{
  "id": "cc0e8400-e29b-41d4-a716-446655440007"      // UUID (required) - Client ID to describe
}
```

### Response

Returns the Client object. The secret is **never included** in describe responses.

```json
{
  "id": "cc0e8400-e29b-41d4-a716-446655440007",     // UUID - Client identifier
  "name": "Payment Service",                         // string - Client name
  "endpoint": "https://payments.example.com/oxideauth/updates",   // string? - Registered update endpoint URL
  "description": "Handles payment processing",       // string? - Description
  "tags": ["payments", "production"],                // string[] - Tags
  "meta": { "schema_version": "1.0" },               // object - Metadata
  "enabled": true,                                   // boolean - Whether the client is active
  "created_at": "2024-01-15T10:30:00Z",              // RFC 3339 - Creation timestamp
  "updated_at": "2024-02-01T09:00:00Z"               // RFC 3339? - Last update timestamp
}
```

---

## List Clients

`POST /clients/list`

Lists all clients within a workspace with optional filtering and pagination.

### Request Body

```json
{
  "filter": {                                        // object (optional) - Filter parameters
    "tags": [],                                      // string[] (optional) - Filter by tags
    "fields": {}                                     // object (optional) - Filter by field values (`id`, `name`, `description`, `enabled`)
  },
  "options": {                                       // object (optional) - Pagination options
    "limit": 10,                                     // integer (optional) - Page size
    "offset": 0,                                     // integer (optional) - Records to skip
    "order_bys": "!created_at"                       // string (optional) - Sort order (`"created_at"` for ASC, `"!created_at"` for DESC)
  }
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "clients": [ ... ],
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

## Update Client

`POST /clients/update`

Updates a client's fields. All fields except `id` are optional — only include what you want to change.

### Request Body

```json
{
  "id": "cc0e8400-e29b-41d4-a716-446655440007",     // UUID (required) - Client ID to update
  "name": "Payment Service v2",                      // string (optional) - New display name
  "endpoint": "https://payments.example.com/v2/oxideauth/updates",   // string (optional) - New update endpoint URL
  "description": "Handles payment processing",       // string (optional) - New description
  "tags": ["payments", "production"],                // string[] (optional) - Replacement tags
  "meta": { "schema_version": "1.0" },               // object (optional) - New metadata
  "enabled": true                                    // boolean (optional) - Enable or disable the client
}
```

### Response

Returns the updated Client object (same schema as Describe response).

---

## Delete Client

`POST /clients/delete`

Deletes a client by ID. Once deleted, the client can no longer validate tokens or receive push updates. **This is a destructive operation.**

### Request Body

```json
{
  "id": "cc0e8400-e29b-41d4-a716-446655440007"      // UUID (required) - Client ID to delete
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "id": "cc0e8400-e29b-41d4-a716-446655440007"
  }
}
```

---

## Regenerate Client Secret

`POST /clients/regenerate-secret`

Rotates the client's secret. The old secret is **immediately invalidated**. Returns the new secret in plaintext — the only time a secret is visible after initial creation.

### Request Body

```json
{
  "id": "cc0e8400-e29b-41d4-a716-446655440007"      // UUID (required) - Client ID
}
```

### Response

```json
{
  "id": "cc0e8400-e29b-41d4-a716-446655440007",     // UUID - Client identifier
  "secret": "oxauth_secret_xyz789"                   // string - New plaintext secret (store immediately — old secret is now invalid)
}
```

!!! warning "Immediate Invalidation"
    The old client secret stops working the moment this endpoint returns successfully. Any service using the old secret will receive `authorized: false` from the validate endpoint until reconfigured with the new secret.
