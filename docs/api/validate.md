# Validate API

Service-to-service token validation. Registered client microservices use this endpoint to verify whether an end user's access token grants sufficient permissions for a requested operation.

!!! info "Authentication"
    This endpoint is mounted in the **protected routes**, so a valid **Bearer token** in the `Authorization` header is **required** — standard OxideAuth auth. **In addition**, the calling client must include its `client_secret` in the request body so the service can identify which registered client is performing the validation. The end user's token (being validated) is passed in the `user_token` field. See [Authentication](#authentication) below.

---

## Authentication

The Validate endpoint is a service-to-service endpoint, but it is mounted in the **protected router** (under `CtxLayer`), so a valid **Bearer token** is required, exactly like other OxideAuth API endpoints. The calling client needs **two** things for every request:

1. **A valid Bearer token** in the `Authorization` header — this authenticates the caller and must carry the `client:validate` permission in the target workspace. The service enforces this via `scope_and_validate_ctx(ctx, workspace_id, &["client:validate"])`. A missing/invalid token is rejected with `401 Unauthorized` by the auth middleware and never reaches the validation logic.
2. **`client_secret`** (plaintext) in the request body — this identifies which registered client is performing the validation. OxideAuth hashes the secret with SHA-256 and compares it against the stored hash; the client's registered workspace is used as the workspace context for the permission checks.

Note that the Bearer token authenticates the **calling client microservice**, while the end user's token being validated is passed separately in the `user_token` field.

---

## Validate

`POST /clients/validate`

Validates a user's access token against a set of required permissions.

### Request Body

```json
{
  "client_secret": "oxauth_secret_abc123def456",       // string (required) - The client's plaintext secret (identifies which registered client performs the validation)
  "user_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",   // string (required) - The end user's JWT Bearer token to validate
  "required_permissions": ["project:read", "account:describe"]   // string[] (required) - The set of permissions the user must possess
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
  "message": "Validation failed: missing field `client_secret`"
}
```

The error body is flat: `success`, `status`, and a single `message` field. There is no nested `error` object and no `code` field.

---

## Validation Flow

The Validate endpoint performs a multi-step check for each request:

1. **Client Authentication**: The provided `client_secret` is hashed with SHA-256 and compared against the stored hash. If no matching client is found (or the secret is wrong), returns `authorized: false`.
2. **Token Decoding**: The `user_token` JWT is decoded and validated:
    - **Signature**: Verified using HS256
    - **Expiry**: The `exp` claim is checked — expired tokens return `authorized: false`
    - **Token Type**: Must be `Auth` type (not password reset, not account confirmation)
3. **Workspace Binding**: The workspace context is resolved from the authenticated client (each client belongs to a workspace). The token's workspace claim is verified against the client's workspace. Mismatched workspaces return `authorized: false`.
4. **Permission Check**: The user's effective permissions (derived from their role and membership bindings) are checked against the `required_permissions` array. All required permissions must be satisfied.

The caller's Bearer token authentication and the `client:validate` permission check happen earlier, in the auth middleware (`CtxLayer`), before the handler runs.

If **any** step fails, the response is `authorized: false`. The specific failure reason is intentionally not exposed.

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
   - Extract the user's Bearer token from the incoming request's `Authorization` header
   - Determine which permissions are required for the requested operation
   - Call `POST /clients/validate` with your service's own Bearer token (with the `client:validate` permission) in the `Authorization` header, your `client_secret` in the body, the user's token, and the required permissions
   - If `authorized` is `true`, proceed with the request; if `false`, return a 401/403 to the user
3. **Push Updates**: Expose an update endpoint on your service (registered as the Client's `endpoint`) to receive cache invalidation notifications when permissions or roles change

See the [Push Model Architecture](../architecture/push-model.md) for details on implementing push-based cache invalidation.
