# Client Validation

Registered clients (microservices) often need to decide, at request time, whether a specific end user may perform a specific action on a specific resource — for example, whether the user may edit a particular blog post. OxideAuth's validate route lets a registered client ask the central service for that decision.

## How It Works

1. The client identifies the principal — the end user making the request — and the target resource.
2. The client supplies a **constraint** alongside the principal: a single Constraint DSL expression (see the [Constraint DSL](../api/policies.md#constraint-dsl) in the [Policy API](../api/policies.md)) that captures the condition the request must satisfy.
3. The central service resolves the user's **effective policy set** — the deduplicated union of their role-attached and membership-attached policies — and evaluates the supplied constraint against the target resource using the policy engine.
4. The central service returns an **allow/deny** decision through the existing validate route, `POST /clients/validate` (see the [Validate API](../api/validate.md)).

Because the client supplies only the principal and the constraint, the check stays declarative: the client never evaluates authorization logic itself, and the central service remains the single authority on policy.

## Example Constraint

A blog microservice may ask: "may this user edit this post?" The constraint captures the ownership condition:

```text
blog.author.id === user.id
```

The left path (`blog.author.id`) resolves against the target resource; the right path `user.id` is reserved and resolves to the authenticated account id of the requesting user. The expression reads: allow only when the blog post's author id equals the requesting user's id. See the [Constraint DSL](../api/policies.md#constraint-dsl) for the full grammar.

## Allow/Deny Outcome Semantics

The decision returned by the validate route follows the policy engine's evaluation semantics:

| Outcome | Meaning |
|---------|---------|
| `allow` | The constraint evaluates to `true` against the user's resolved policy set, and no explicit `deny` policy applies |
| `deny` | The constraint evaluates to `false`, an explicit `deny` policy overrides any `allow`, or no policy grants the action (anything not allowed is denied by default) |

Authorization failures are intentionally indistinguishable from one another at the wire level: the route returns a flat allow/deny result without exposing which policy, constraint, or token detail caused the denial. Concrete request and response shapes for `POST /clients/validate` are documented in the [Validate API](../api/validate.md).

The outcome can then be used to gate the client's own handler, for example by returning `401`/`403` to the end user when the decision is `deny`.
