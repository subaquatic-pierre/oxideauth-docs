# Push Model

The Push Model is OxideAuth's mechanism for propagating authorization state changes to registered client microservices in near-real-time. Instead of requiring clients to poll for changes, OxideAuth actively pushes cache invalidation notifications whenever the authorization state changes.

## Why Push?

Authorization systems face a consistency challenge: when permissions, roles, memberships, or tokens change in the central authority, client microservices with local caches may continue enforcing stale authorization rules.

**Polling** (clients periodically checking for changes) has drawbacks:
- **Latency**: Changes take up to the poll interval to propagate (typically 30-60 seconds)
- **Waste**: Most polls return "no changes", consuming resources for nothing
- **Scalability**: As the number of clients grows, polling load increases linearly

**Push** (OxideAuth notifying clients of changes) addresses these:
- **Near-real-time**: Changes propagate within seconds
- **Efficient**: Resources are only consumed when changes actually occur
- **Scalable**: Each change is pushed once per workspace, regardless of client count

## Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                        OxideAuth                             │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌────────────┐  ┌──────────┐  │
│  │ Permission│  │   Role   │  │ Membership │  │   Auth   │  │
│  │  Service  │  │ Service  │  │  Service   │  │ Service  │  │
│  └────┬─────┘  └────┬─────┘  └─────┬──────┘  └────┬─────┘  │
│       │              │              │               │        │
│       └──────────────┼──────────────┼───────────────┘        │
│                      ▼              ▼                        │
│              ┌──────────────────────────────┐                │
│              │     Client Push Service      │                │
│              │  push_to_workspace(ws_id,    │                │
│              │    type, resource_ids)        │                │
│              └─────────────┬────────────────┘                │
│                            │                                 │
└────────────────────────────┼─────────────────────────────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
        ┌──────────┐  ┌──────────┐  ┌──────────┐
        │ Client A │  │ Client B │  │ Client C │
        │ endpoint │  │ endpoint │  │ endpoint │
        └──────────┘  └──────────┘  └──────────┘
```

## How It Works

### 1. State Change Occurs

When any of the following mutations happen in OxideAuth, the push mechanism is triggered:

| Event | Service | `type` Value |
|-------|---------|-------------|
| Token revoked (logout) | Auth | `token` |
| Permission created | Permission | `permission` |
| Permission updated | Permission | `permission` |
| Permission deleted | Permission | `permission` |
| Role created | Role | `role` |
| Role updated | Role | `role` |
| Role deleted | Role | `role` |
| Membership created | Membership | `membership` |
| Membership updated | Membership | `membership` |
| Membership deleted | Membership | `membership` |

### 2. Push Payload Generated

The Client Push Service constructs a JSON payload containing the minimum information needed for cache invalidation:

```json
{
  "type": "permission",
  "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
  "resource_ids": [
    "660e8400-e29b-41d4-a716-446655440001"
  ],
  "timestamp": "2026-08-07T12:00:00Z"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | Resource type that changed: `permission`, `role`, `membership`, or `token` |
| `workspace_id` | UUID | The workspace where the change occurred |
| `resource_ids` | UUID[] | One or more entity IDs affected by the change |
| `timestamp` | RFC 3339 | When the change was committed (UTC) |

### 3. Delivery to Clients

The push service lists all active clients in the affected workspace and delivers the payload to each client's registered `endpoint` URL via HTTP POST:

```
POST <client.endpoint>
Content-Type: application/json
{ ... payload ... }
```

### 4. Client Processes Update

Upon receiving a push notification, the client microservice should:

1. **Acknowledge receipt** by returning HTTP 2xx
2. **Parse the payload** to identify the `type` and `resource_ids`
3. **Invalidate relevant cache entries**:
   - `type: "token"` → remove cached token authorization results for the affected tokens
   - `type: "permission"` → remove cached permission checks involving the affected permissions
   - `type: "role"` → remove cached role definitions and their permission mappings
   - `type: "membership"` → remove cached membership records and derived permissions
4. **Let the next user request** trigger a fresh validate call, which will fetch the updated authorization state

## Delivery Guarantees

| Property | Behavior |
|----------|----------|
| **Delivery model** | At-least-once: each notification may be delivered more than once |
| **Retry count** | Up to 3 attempts per client |
| **Retry backoff** | Exponential: 1 second, 5 seconds, 25 seconds between attempts |
| **Timeout** | Connection timeout per attempt (server-configurable) |
| **Ordering** | Best-effort: notifications may arrive out of order |
| **Idempotency** | Clients must handle duplicate deliveries gracefully |

!!! tip "Handling Duplicates"
    Since pushes may be delivered more than once (retries, network conditions), client implementations should treat push notifications as idempotent. Invalidating an already-invalidated cache entry is harmless — the next validate call will fetch fresh data regardless.

## Push Counters

OxideAuth tracks push delivery metrics per client via Redis counters:

| Counter | Redis Key Pattern | Description |
|---------|------------------|-------------|
| Success | `oxauth:cl:push:ok:{client_id}` | Incremented on each successful delivery (2xx response) |
| Failure | `oxauth:cl:push:fail:{client_id}` | Incremented when all retries are exhausted without success |

These counters can be used for monitoring and alerting — a rising failure count indicates a client's endpoint may be unreachable.

## Client Implementation Requirements

To receive push updates, a client microservice must:

1. **Register an endpoint URL** — set the `endpoint` field when creating the client. This URL must be reachable from the OxideAuth server (not localhost unless OxideAuth is on the same network).

2. **Accept POST requests** with `Content-Type: application/json` at the registered endpoint.

3. **Return HTTP 2xx** on successful receipt. The response body is not inspected — only the status code matters.

4. **Handle duplicate deliveries** — the same payload may arrive multiple times due to retries. Your cache invalidation logic should be idempotent.

5. **Invalidate relevant cache** — based on `type` and `resource_ids`, remove or mark-as-stale any locally cached authorization data involving the specified resources.

6. **Respond quickly** — recommended response time is under 5 seconds. Slow responses hold up the OxideAuth push worker. If processing is expensive, acknowledge immediately (return 2xx) and process asynchronously.

## Failure Handling

### Client Unreachable

If a client's endpoint is unreachable (network error, timeout, DNS failure), OxideAuth retries up to 3 times with exponential backoff. After all retries are exhausted:

- The failure is logged
- The failure counter for that client is incremented
- **No further action is taken** — the notification is dropped

This design accepts that occasional push failures can occur. The system relies on the next user request to the microservice triggering a fresh validate call, which will naturally reflect the updated authorization state. The push mechanism optimizes for the common case (reducing latency and load) while degrading gracefully when clients are unavailable.

### Stale Caches

Between a state change in OxideAuth and the push notification being processed by a client, there is a brief window where the client's cache may be stale. This is an accepted tradeoff:

- **Push minimizes this window** to seconds (vs. minutes with polling)
- **Clients can choose cache TTLs** that match their security requirements — shorter TTLs reduce the stale window at the cost of more validate calls
- **Critical operations** can bypass the cache entirely and always call validate

## Comparison with Models in Other Systems

| Aspect | OxideAuth Push | Traditional Polling | Webhooks |
|--------|---------------|--------------------|-----------|
| **Latency** | Seconds | Poll interval (30-60s typical) | Instant |
| **Client complexity** | Must expose endpoint | Simple (periodic GET) | Must expose endpoint |
| **Server load** | Proportional to changes | Proportional to clients × poll frequency | Proportional to changes |
| **Retry logic** | Built-in (3 retries) | Client-managed | Varies by provider |
| **Ordering** | Best-effort | N/A (snapshot-based) | Varies |

## See Also

- [Clients Entity](clients.md) — how the Client entity fits into the IAM model
- [Validate API](../api/validate.md) — the runtime endpoint for token validation
- [Clients API](../api/clients.md) — managing clients via the API
- [Token Architecture](token.md) — how tokens are issued, validated, and revoked
