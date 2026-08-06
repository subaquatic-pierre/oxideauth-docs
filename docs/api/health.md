# Health Endpoints

Root and health-check endpoints for verifying server liveness.

**Authentication:** Not required.

---

## `GET /`

Root index endpoint. Returns a simple greeting.

### Request

```http
GET / HTTP/1.1
Host: 127.0.0.1:8000
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": "Hello, World"
}
```

---

## `GET /health-check`

Server health check. Returns `"Healthy"` when the server is running and able to serve requests.

### Request

```http
GET /health-check HTTP/1.1
Host: 127.0.0.1:8000
```

### Response

```json
{
  "success": true,
  "status": 200,
  "data": "Healthy"
}
```

### Usage

```bash
# Quick liveness check
curl -s http://127.0.0.1:8000/health-check | jq '.data'
# "Healthy"

# Use as a Docker health check
curl --fail http://127.0.0.1:8000/health-check || exit 1
```
