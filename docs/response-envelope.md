# Response Envelope

All API responses follow a consistent JSON envelope structure.

## Format

```json
{
  "success": true,
  "status": 200,
  "data": { ... }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | Always `true` for successful responses |
| `status` | integer | HTTP status code (redundant, useful for client debugging) |
| `data` | object/array/string | The actual response payload |

## Error Responses

Errors are returned with an HTTP error status code and a JSON body describing the failure:

```json
{
  "success": false,
  "status": 401,
  "message": "Invalid or expired token"
}
```

### Common Error Codes

| Status | Meaning |
|--------|---------|
| `400` | Invalid request body, validation errors, or duplicate resources (malformed JSON, missing/invalid fields, duplicate email/slug/name) |
| `401` | Missing, expired, or revoked token |
| `403` | Insufficient permissions for the requested operation |
| `404` | Resource not found or unknown route |
| `500` | Internal server error |

## Single-Resource Response

When retrieving or creating a single resource, `data` contains the full resource object:

```json
{
  "success": true,
  "status": 200,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Alice Johnson",
    "email": "alice@example.com",
    "enabled": true,
    "verified": false,
    "tags": ["engineering"],
    "created_at": "2026-08-06T12:00:00Z",
    "updated_at": null
  }
}
```

## List Response

List endpoints return a paginated response with metadata:

```json
{
  "success": true,
  "status": 200,
  "data": {
    "accounts": [
      { "id": "...", "name": "Alice", ... },
      { "id": "...", "name": "Bob", ... }
    ],
    "metadata": {
      "total": 42,
      "count": 10,
      "offset": 0,
      "limit": 10,
      "order_bys": ["!created_at"]
    }
  }
}
```

### List Metadata Fields

| Field | Type | Description |
|-------|------|-------------|
| `total` | integer | Total matching records (ignoring pagination) |
| `count` | integer | Records in the current page |
| `offset` | integer or null | Current offset |
| `limit` | integer | Page size |
| `order_bys` | string[] | Active sort orders (`!` prefix = descending) |

## Delete Response

Delete endpoints return the deleted resource's identifier:

```json
{
  "success": true,
  "status": 200,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000"
  }
}
```

## Audit Fields

All resources include standard audit timestamps:

| Field | Type | Description |
|-------|------|-------------|
| `created_at` | RFC 3339 | When the resource was created |
| `updated_at` | RFC 3339 or null | When the resource was last updated (`null` if never updated) |

## Extensibility Fields

All resources support extensibility through two standard fields:

| Field | Type | Description |
|-------|------|-------------|
| `tags` | string[] | Arbitrary tags for categorization and filtering |
| `meta` | object | Extensible JSON metadata (`schema_version` required) |
