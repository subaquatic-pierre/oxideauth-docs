# Auth API

Authentication endpoints for local email/password login, Google OAuth2, token management, password reset, and account verification.

**Public endpoints** (no Bearer token required): Register, Login, Reset Password, Update Password, Confirm Account, Resend Confirm, OAuth Initiate, OAuth Callback.

**Protected endpoints** (Bearer token required): Refresh Token, Revoke Token.

---

## Register

`POST /auth/register`

Creates a new local account with email and password. Returns a JWT token and the account object.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `email` | string | Yes | Unique email address |
| `password` | string | Yes | Account password (non-empty) |
| `name` | string | No | Display name |

### Example Request

```json
{
  "email": "newuser@example.com",
  "password": "SecureP@ssw0rd!",
  "name": "New User"
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "account": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "newuser@example.com",
      "name": "New User",
      "verified": false,
      "enabled": true
    }
  }
}
```

### Possible Errors

| Status | Code | Description |
|:------:|------|-------------|
| 400 | `EMAIL_EXISTS` | An account with this email already exists |
| 400 | `EMPTY_PASSWORD` | Password cannot be empty |
| 400 | `INVALID_EMAIL` | Email format is invalid |

---

## Login

`POST /auth/login`

Authenticates with email and password credentials. Returns a JWT token (60-minute TTL) and the account object.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `email` | string | Yes | Registered email address |
| `password` | string | Yes | Account password |

### Example Request

```json
{
  "email": "user@email.com",
  "password": "password"
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "account": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "user@email.com",
      "name": "...",
      "verified": true,
      "enabled": true
    }
  }
}
```

### Possible Errors

| Status | Code | Description |
|:------:|------|-------------|
| 401 | `INVALID_CREDENTIALS` | Wrong email or password |
| 401 | `ACCOUNT_LOCKED` | Rate limit hit — 5 failed attempts triggers 15-min lockout |
| 401 | `ACCOUNT_DISABLED` | Account has been disabled |
| 400 | `OAUTH_ONLY` | Account was created via OAuth (use Google login or reset password) |

---

## Refresh Token

`POST /auth/refresh`

Exchanges a valid Bearer token for a new JWT with renewed expiry (60 minutes from now). No request body required — the current token in the Authorization header provides identity.

**Auth required:** Bearer token

### Example Request

```json
{}
```

### Request Headers

```
Authorization: Bearer eyJ...
Content-Type: application/json
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ..."
  }
}
```

### Possible Errors

| Status | Code | Description |
|:------:|------|-------------|
| 401 | `INVALID_TOKEN` | Token is missing, expired, or revoked |
| 401 | `ACCOUNT_DISABLED` | Account has been disabled |

---

## Reset Password (Request)

`POST /auth/reset-password`

Requests a password reset email for the given address. Always returns success to prevent email enumeration. The reset token (24h TTL) is logged server-side and included in the email.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `email` | string | Yes | The account email address |

### Example Request

```json
{
  "email": "user@email.com"
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "message": "If an account exists for this email, a reset link has been sent."
  }
}
```

!!! note "Anti-Enumeration"
    If the email does not exist in the system, the same success response is returned. No email is sent in that case.

---

## Update Password (with Reset Token)

`POST /auth/update-password`

Sets a new password using a valid password reset token. The token must be of type `PasswordReset` and not expired (24h TTL).

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `token` | string | Yes | JWT password reset token |
| `password` | string | Yes | New password (non-empty) |

### Example Request

```json
{
  "token": "eyJ...",
  "password": "NewSecureP@ssw0rd!"
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "account_id": "550e8400-e29b-41d4-a716-446655440000"
  }
}
```

### Possible Errors

| Status | Code | Description |
|:------:|------|-------------|
| 400 | `INVALID_TOKEN` | Token is expired or malformed |
| 400 | `WRONG_TOKEN_TYPE` | Token is not a PasswordReset token (e.g., using a confirmation token) |
| 401 | `ACCOUNT_DISABLED` | Account has been disabled |

---

## Confirm Account

`POST /auth/confirm`

Verifies a user's email address using a confirmation token generated during registration. The token must be of type `AccountConfirm` and not expired (24h TTL).

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `token` | string | Yes | JWT confirmation token from registration email |

### Example Request

```json
{
  "token": "eyJ..."
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "account_id": "550e8400-e29b-41d4-a716-446655440000",
    "verified": true
  }
}
```

### Possible Errors

| Status | Code | Description |
|:------:|------|-------------|
| 400 | `INVALID_TOKEN` | Token is expired or malformed |
| 400 | `WRONG_TOKEN_TYPE` | Token is not an AccountConfirm token |
| 400 | `ALREADY_VERIFIED` | Account is already verified |

---

## Resend Confirmation Email

`POST /auth/resend-confirm`

Resends the account confirmation email for an unverified account. Silently succeeds if the account doesn't exist (anti-enumeration).

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `email` | string | Yes | The account email address |

### Example Request

```json
{
  "email": "newuser@example.com"
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "message": "If an unverified account exists, a new confirmation email has been sent."
  }
}
```

### Possible Errors

| Status | Code | Description |
|:------:|------|-------------|
| 400 | `ALREADY_VERIFIED` | Account is already verified |

---

## Revoke Token (Logout)

`POST /auth/revoke`

Revokes the current JWT token, rendering it invalid for future requests. The token is blacklisted in Redis with a TTL matching its remaining lifetime and persisted to the database.

**Auth required:** Bearer token (the token being revoked)

### Example Request

```json
{}
```

### Request Headers

```
Authorization: Bearer eyJ...
Content-Type: application/json
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "revoked": true
  }
}
```

### Possible Errors

| Status | Code | Description |
|:------:|------|-------------|
| 401 | `INVALID_TOKEN` | Token is missing, expired, or already revoked |

---


## OAuth: Initiate Google Login

`POST /auth/oauth/google/initiate`

Starts the Google OAuth2 login flow. Generates a cryptographically random CSRF token, stores it in Redis (10-min TTL), and returns the complete Google authorization URL that the client should redirect the user to.

### Request Body

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `redirect_url` | string | Yes | Where to redirect the user after OAuth completes (your app's callback page) |

### Example Request

```json
{
  "redirect_url": "http://localhost:5000/dashboard"
}
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": {
    "auth_url": "https://accounts.google.com/o/oauth2/v2/auth?client_id=...&redirect_uri=...&response_type=code&scope=openid+email+profile&state=..."
  }
}
```

---

## OAuth: Google Callback

`GET /auth/oauth/google/callback`

Read-only GET endpoint that Google redirects the user to after they complete the consent screen. Processes the authorization code, exchanges it for tokens, fetches the Google user profile, creates or links an account, and redirects the user to the client-provided `redirect_url` with the JWT token as a query parameter.

**This is NOT a JSON endpoint** — it returns a `302 Found` redirect.

### Query Parameters

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `code` | string | Yes | Google OAuth2 authorization code |
| `state` | string | Yes | CSRF state token (validated against Redis) |

### Success Redirect

```http
HTTP/1.1 302 Found
Location: http://localhost:5000/dashboard?token=eyJ...
```

### Error Redirects

| Error | Parameter | Description |
|-------|-----------|-------------|
| CSRF mismatch | `?error=invalid_state` | State token doesn't match or has expired |
| OAuth failure | `?error=oauth_failed` | Google API error or invalid authorization code |

!!! note "Browser Endpoint"
    This endpoint is meant to be called by the browser (Google redirect), not directly via an API client. Use the OAuth Initiate endpoint to get the `auth_url`, then follow it in a browser.

---

## Auth Flow Summary

| Step | Endpoint | Auth | Result |
|------|----------|:----:|--------|
| 1 | `POST /auth/register` | No | Creates account + returns `token` |
| 2 | `POST /auth/login` | No | Authenticates + returns `token` |
| 3 | `POST /auth/refresh` | Yes | Renews `token` before expiry |
| 4 | `POST /auth/revoke` | Yes | Invalidates `token` (logout) |
| — | `POST /auth/reset-password` | No | Sends password reset email |
| — | `POST /auth/update-password` | No | Sets new password via reset token |
| — | `POST /auth/confirm` | No | Verifies email address |
| — | `POST /auth/resend-confirm` | No | Resends confirmation email |
| — | `POST /auth/oauth/google/initiate` | No | Starts Google OAuth2 flow |
| — | `GET /auth/oauth/google/callback` | No | Completes Google OAuth2 flow |
