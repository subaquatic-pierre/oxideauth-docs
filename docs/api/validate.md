# Validate API

Service-to-service token validation. Registered client microservices use this endpoint to verify whether an end user's access token grants sufficient permissions for a requested operation.

!!! info "Client Secret Authentication"
    This endpoint authenticates the **calling client** via its `client_secret` in the request body — **not** via a user Bearer token. The user's token (being validated) is passed in the `user_token` field. See [Authentication](#authentication) below.

---

## Authentication

The Validate endpoint is a service-to-service endpoint. Unlike most OxideAuth API endpoints which require a Bearer token in the `Authorization` header, the Validate endpoint authenticates the calling client by:

1. The client includes its `client_secret` (plaintext) in the request body
2. OxideAuth hashes the secret with SHA-256 and compares it against the stored hash
3. If the hash matches, the client is authenticated and the validation proceeds

This design allows client microservices to validate tokens without managing their own Bearer token lifecycle.

---

## Validate

`POST /clients/validate`

Validates a user's access token against a set of required permissions.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `workspace_id` | UUID | Yes | The workspace context for the validation |
| `client_secret` | string | Yes | The client's plaintext secret (authenticates the client) |
| `user_token` | string | Yes | The end user's JWT Bearer token to validate |
| `required_permissions` | string[] | Yes | The set of permissions the user must possess |

### Example Request

```json
{
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "client_secret": "oxauth_secret_abc123def456",
  "user_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "required_permissions": ["project:read", "account:describe"]
}
```

### Success Response (Authorized)

```json
{
  "success": true,
  "status": 200,
  "data": {
    "authorized": true
  }
}
```

### Denial Response (Not Authorized)

When the token is invalid, expired, revoked, or lacks required permissions, the endpoint returns `authorized: false` with HTTP 200 (not a 4xx error). This prevents information leakage about the existence of clients or the validity of tokens.

```json
{
  "success": true,
  "status": 200,
  "data": {
    "authorized": false
  }
}
```

!!! note "Always HTTP 200"
    Authorization failures (invalid token, expired token, insufficient permissions, client not found, invalid secret) all return `{"authorized": false}` with HTTP 200. This prevents attackers from distinguishing between "client not found", "bad secret", and "token invalid" — a security measure against enumeration attacks.

### Validation Error Response

Returned only when the request body fails structural validation (e.g., missing required fields, invalid UUID format).

```json
{
  "success": false,
  "status": 400,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Missing required field: workspace_id"
  }
}
```

---

## Validation Flow

The Validate endpoint performs a multi-step check for each request:

1. **Client Authentication**: The provided `client_secret` is hashed with SHA-256 and compared against the stored hash. If no matching client is found (or the secret is wrong), returns `authorized: false`.
2. **Rate Limit Check**: A per-client sliding window rate limit is applied. If the client has exceeded the threshold, returns `authorized: false`. See [Rate Limiting](#rate-limiting).
3. **Token Decoding**: The `user_token` JWT is decoded and validated:
    - **Signature**: Verified using HS256
    - **Expiry**: The `exp` claim is checked — expired tokens return `authorized: false`
    - **Token Type**: Must be `Auth` type (not password reset, not account confirmation)
4. **Workspace Binding**: The token's workspace claim is verified against the provided `workspace_id`. Mismatched workspaces return `authorized: false`.
5. **Permission Check**: The user's effective permissions (derived from their role and membership bindings) are checked against the `required_permissions` array. All required permissions must be satisfied.

If **any** step fails, the response is `authorized: false`. The specific failure reason is intentionally not exposed.

---

## Rate Limiting

The Validate endpoint is rate-limited per client to prevent abuse. Rate limiting details:

- **Scope**: Per-client, based on the authenticated `client_secret`
- **Algorithm**: Sliding window
- **Exceeded behavior**: Returns `authorized: false` (not a 429 HTTP error) to avoid leaking client existence
- **Configuration**: Rate limit window and threshold are server-configurable

!!! tip "Client-Side Handling"
    If your service receives `authorized: false` responses in bursts, it may be hitting the rate limit. Implement exponential backoff on the client side and consider caching validation results locally where appropriate (with appropriate TTLs matching your security requirements).

---

## Permission Reference

Common permission strings that may appear in `required_permissions`:

| Permission | Description |
|------------|-------------|
| `workspace:describe` | View workspace details |
| `workspace:update` | Update workspace settings |
| `account:describe` | View account details |
| `account:list` | List accounts in a workspace |
| `account:create` | Create new accounts |
| `account:update` | Update account details |
| `account:delete` | Delete accounts |
| `project:create` | Create projects |
| `project:read` | Read project details |
| `project:update` | Update project details |
| `project:delete` | Delete projects |
| `role:describe` | View role details |
| `role:list` | List roles |
| `role:create` | Create roles |
| `role:update` | Update roles |
| `role:delete` | Delete roles |
| `permission:describe` | View permission details |
| `permission:list` | List permissions |
| `membership:describe` | View membership details |
| `membership:list` | List memberships |
| `client:describe` | View client details |
| `client:list` | List clients in a workspace |
| `credential:describe` | View credential details |
| `credential:list` | List credentials in a workspace |

For the most up-to-date permission list, consult the [Permissions API](../api/permissions.md) or your workspace's configured permission set.

---

## Integration Example

A typical microservice integration pattern:

1. **Registration**: Create a Client via the API (see [Clients API](../api/clients.md)) and store the returned `secret`
2. **Request Handling**: For each incoming user request to your service:
   - Extract the user's Bearer token from the `Authorization` header
   - Determine which permissions are required for the requested operation
   - Call `POST /clients/validate` with your `client_secret`, the user's token, and the required permissions
   - If `authorized` is `true`, proceed with the request; if `false`, return a 401/403 to the user
3. **Push Updates**: Expose an update endpoint on your service (registered as the Client's `endpoint`) to receive cache invalidation notifications when permissions or roles change

See the [Push Model Architecture](../architecture/push-model.md) for details on implementing push-based cache invalidation.
