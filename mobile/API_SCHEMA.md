# API Schema

The mobile app communicates with a REST API.

Base URL example:

http://localhost:3000

## Endpoints

### GET /occurrences

Returns a list of occurrences.

Example response:

```json
{
 "id": 1,
 "type": "abandonment",
 "description": "dog tied to a gate",
 "location": "Rua Central",
 "status": "pending"
}
```

---

### PATCH /occurrences/:id/status

Update occurrence status.

Request body:

```json
{
 "status": "resolved"
}
```

---

### POST /animals

Register a rescued animal.

Example request:

```json
{
 "name": "Thor",
 "species": "dog",
 "age": 2,
 "description": "rescued from abandonment",
 "status": "under_treatment"
}
```

---

### GET /animals

Returns a list of animals registered by the NGO.
