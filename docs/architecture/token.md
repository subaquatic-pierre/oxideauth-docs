# Token Architecture

Tokens are the core authentication primitive in OxideAuth. This page describes how tokens are issued, validated, and revoked, and why revocation is **version-based** rather than storage-based.

## 1. Stateless JWT Auth

OxideAuth uses **HS256-signed JSON Web Tokens (JWTs)** for request authentication. The server trusts a token based on its cryptographic signature — there is no per-request session lookup and no database read to validate the token itself.

Every authenticated request presents the token in the `Authorization: Bearer <jwt>` header. Validation consists of:

1. **Signature check** — verify the HMAC-SHA256 signature against the `JWT_SECRET` (CPU only).
2. **Expiration check** — reject tokens whose `exp` claim is in the past.
3. **Version check** — validate the token's version/session claims against cached auth data (see [Version-Based Revocation](#4-version-based-revocation)).

Because validation is signature-based, authentication is fast and horizontally scalable: any instance holding the shared secret can validate any token.

## 2. Token Types

| Type             | Purpose                                           | Lifetime                                             |
| ---------------- | ------------------------------------------------- | ---------------------------------------------------- |
| `Auth`           | Standard access token sent on every API request   | ~15 minutes (configurable via `ACCESS_TOKEN_MAXAGE`) |
| `Refresh`        | Long-lived token used to obtain a new `Auth` token | 7 days (configurable via `REFRESH_TOKEN_MAXAGE`)    |
| `PasswordReset`  | Single-use token for password recovery flows      | Short-lived, single use                              |
| `AccountConfirm` | Single-use token for email verification           | Short-lived, single use                              |

Access tokens are short-lived so the window in which a leaked token can be abused stays small. `Refresh` tokens carry a session (`sid`) and a unique `jti` so they can be rotated and their reuse detected. `PasswordReset` and `AccountConfirm` tokens are single-use and are consumed by the flow that validates them.

## 3. Token Claims

Every token is a JWT payload carrying the `TokenClaims` structure:

| Claim     | Type            | Description                                                        |
| --------- | --------------- | ------------------------------------------------------------------ |
| `sub`     | UUID            | Account ID of the authenticated user                               |
| `ws`      | UUID            | Workspace ID the token is scoped to                                |
| `mem`     | UUID            | Membership ID for the current session                              |
| `iss`     | string          | Token issuer                                                       |
| `aud`     | string          | Token audience                                                     |
| `exp`     | integer         | Expiration timestamp (Unix epoch)                                  |
| `iat`     | integer         | Issued-at timestamp (Unix epoch)                                   |
| `ty`      | string          | Token type (`Auth`, `Refresh`, `PasswordReset`, `AccountConfirm`)  |
| `mem_ver` | integer         | Membership token version — powers revocation                       |
| `acc_ver` | integer         | Account token version — powers revocation                          |
| `sid`     | UUID (optional) | Session ID; `null` for single-use tokens                           |
| `jti`     | UUID (optional) | JWT ID — unique per token; `null` for single-use tokens            |

`mem_ver`, `acc_ver`, and `sid` are the claims that make revocation possible in a stateless system: they bind the token to a specific version of the membership and account, and to a specific session. `jti` uniquely identifies each token instance and is what makes refresh tokens single-use.

## 4. Version-Based Revocation

There is **no blacklist, no hash table, and no database write** involved in revocation. Instead, revocation is a *version comparison* between the token's claims and the current cached auth state.

On every authenticated request, the `CtxMiddleware`:

1. Decodes the JWT and reads `mem_ver`, `acc_ver`, and `sid`.
2. Loads the cached auth data (membership version, account version, session) from Redis.
3. Compares the claims against it:
   - `claims.mem_ver` must equal the cached **membership version**
   - `claims.acc_ver` must equal the cached **account version**
   - `claims.sid` must match the cached **session** (when the cached entity carries a session)

If any comparison fails, the request is rejected with `401 Unauthorized` ("token revoked"). The version comparison **is** the revocation check — there is no lookup of revoked tokens anywhere.

### Revoking a Token

`POST /auth/revoke` (the `revoke_token` service) decodes the bearer token to recover its claims, verifies the caller holds the `auth:revoke` permission, then **bumps the membership version** and **purges the membership/account auth-cache keys**. No hash is computed and no database row is written.

As soon as the version bumps, every previously-issued token carrying the old `mem_ver`/`acc_ver` fails validation on its next request. All tokens for that membership/account are revoked **immediately**, with no per-token state to store or sweep.

## 5. Refresh-Token Single Use

`Refresh` tokens are single-use. Each refresh token carries a unique `jti`. On its first use, the refresh service marks it as consumed under the cache key `oxauth:crt:{jti}` (recording the session that used it, with a TTL equal to the token's remaining life).

Any subsequent presentation of the same `jti` is detected as a **replay**: the session is treated as compromised, the membership version is bumped (invalidating every outstanding token for that session), and the auth cache is purged.

## 6. Security Trade-offs

- **Fail-open on signature trust** — tokens are accepted on the strength of the signature alone: no session lookup, no per-request database hit. This keeps authentication fast and stateless.
- **Fail-closed on cache cold** — the version comparison is strict. A token whose version/session claims do not match the current cached auth data is rejected with `401`. On a cache miss the auth data is re-hydrated from the database, so revocation state is never silently lost.
- **Window of risk** — because access tokens live only ~15 minutes, the window in which a revoked-but-unexpired token could be presented is bounded by the access-token lifetime. Version-based revocation collapses that window to effectively zero in normal operation, and the short lifetime bounds the worst case.
