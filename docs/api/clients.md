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

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | Owning workspace |
| `name` | string | Yes | Human-readable name for the client |
| `endpoint` | string | No | Update endpoint URL that OxideAuth calls to push cache invalidation events |
| `description` | string | No | Optional description |
| `tags` | string[] | No | Categorization tags |
| `meta` | object | No | Extensible metadata (`schema_version` required) |

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Payment Service",
  "endpoint": "https://payments.example.com/oxideauth/updates",
  "description": "Handles payment processing and needs to validate user tokens",
  "tags": ["payments", "production"],
  "meta": { "schema_version": "1.0" }
}
```

### Response

Returns the created Client object. The `secret` field is **only returned on creation and regeneration** — it is never included in describe or list responses.

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Client identifier |
| `workspace_id` | UUID | Owning workspace |
| `name` | string | Client name |
| `secret` | string | **Plaintext secret** (only returned once — store immediately) |
| `endpoint` | string? | Registered update endpoint URL |
| `description` | string? | Description |
| `tags` | string[] | Tags |
| `meta` | object | Metadata |
| `created_at` | RFC 3339 | Creation timestamp |

!!! danger "Secret Storage"
    The `secret` field appears only in the create response. There is no way to retrieve a lost secret — you must regenerate it (see [Regenerate Client Secret](#regenerate-client-secret)).

---

## Describe Client

`POST /clients/describe`

Retrieves a client by ID within a workspace.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | Workspace context |
| `id` | UUID | Yes | Client ID to describe |

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "id": "cc0e8400-e29b-41d4-a716-446655440007"
}
```

### Response

Returns the Client object. The secret is **never included** in describe responses.

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Client identifier |
| `workspace_id` | UUID | Owning workspace |
| `name` | string | Client name |
| `endpoint` | string? | Registered update endpoint URL |
| `description` | string? | Description |
| `tags` | string[] | Tags |
| `meta` | object | Metadata |
| `enabled` | boolean | Whether the client is active |
| `created_at` | RFC 3339 | Creation timestamp |
| `updated_at` | RFC 3339? | Last update timestamp |

---

## List Clients

`POST /clients/list`

Lists all clients within a workspace with optional filtering and pagination.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | Workspace context |
| `filter` | object | No | Filter parameters |
| `options` | object | No | Pagination options |

### Filter Fields (`filter.fields`)

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Filter by client ID |
| `name` | string | Filter by name |
| `description` | string | Filter by description |
| `enabled` | boolean | Filter by enabled/disabled status |

### Options

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `limit` | integer | — | Page size |
| `offset` | integer | — | Records to skip |
| `order_bys` | string | — | Sort order (`"created_at"` for ASC, `"!created_at"` for DESC) |

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "filter": {
    "tags": [],
    "fields": {}
  },
  "options": {
    "limit": 10,
    "offset": 0,
    "order_bys": "!created_at"
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

Updates a client's fields. All fields except `workspace_id` and `id` are optional — only include what you want to change.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | Workspace context |
| `id` | UUID | Yes | Client ID to update |
| `name` | string | No | New display name |
| `endpoint` | string | No | New update endpoint URL |
| `description` | string | No | New description |
| `tags` | string[] | No | Replacement tags |
| `meta` | object | No | New metadata |
| `enabled` | boolean | No | Enable or disable the client |

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "id": "cc0e8400-e29b-41d4-a716-446655440007",
  "name": "Payment Service v2",
  "endpoint": "https://payments.example.com/v2/oxideauth/updates",
  "enabled": true
}
```

### Response

Returns the updated Client object (same schema as Describe response).

---

## Delete Client

`POST /clients/delete`

Deletes a client by ID. Once deleted, the client can no longer validate tokens or receive push updates. **This is a destructive operation.**

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | Workspace context |
| `id` | UUID | Yes | Client ID to delete |

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "id": "cc0e8400-e29b-41d4-a716-446655440007"
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

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | Workspace context |
| `id` | UUID | Yes | Client ID |

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "id": "cc0e8400-e29b-41d4-a716-446655440007"
}
```

### Response

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Client identifier |
| `secret` | string | **New plaintext secret** (store immediately — old secret is now invalid) |

!!! warning "Immediate Invalidation"
    The old client secret stops working the moment this endpoint returns successfully. Any service using the old secret will receive `authorized: false` from the validate endpoint until reconfigured with the new secret.
