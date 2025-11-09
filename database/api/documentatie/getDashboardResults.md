# ICCA Dashboard API – Documentation

## 🔗 Base URLs
- **API Base URL:** `https://icca-dashboard.maxapex.net/ords/icca/api`
- **OAuth Token URL:** `https://icca-dashboard.maxapex.net/ords/icca/oauth/token`

---

## 🔐 Authentication

This API uses **OAuth 2.0 Client Credentials Grant**.

### Token Request

**Endpoint:**
```
POST https://icca-dashboard.maxapex.net/ords/icca/oauth/token
```

**Headers:**
| Header | Value |
|--------|--------|
| `Content-Type` | `application/x-www-form-urlencoded` |
| `Authorization` | `Basic <base64(client_id:client_secret)>` |

**Body:**
```
grant_type=client_credentials
```

**Response Example:**
```json
{
  "access_token": "eyJhbGciOi...",
  "token_type": "bearer",
  "expires_in": 3600
}
```

Once you have the token, include it in all requests as:
```
Authorization: Bearer <access_token>
```

---

## Endpoint: `GET /getDashboardResults`

### Description
Fetches dashboard audit results with optional filters for company, audit, year, and month.

**Full URL:**
```
https://icca-dashboard.maxapex.net/ords/icca/api/getDashboardResults
```

### Query Parameters

| Parameter | Type | Required | Description |
|------------|------|-----------|--------------|
| `company_name` | string | No | Filter by company name |
| `audit_code` | string | No | Filter by audit code |
| `jaar` | number | No | Filter by year (e.g., 2023) |
| `maand` | number | No | Filter by month (1–12) |
| `page` | number | No | Page number (for pagination) |
| `page_size` | number | No | Number of results per page (default 100) |

### Example Request

```js
const response = await axios.get('https://icca-dashboard.maxapex.net/ords/icca/api/getDashboardResults', {
  headers: { Authorization: `Bearer ${accessToken}` },
  params: { company_name: 'Stichting Kolom', jaar: 2023, maand: 12 }
});
```

### Example Response

```json
{
  "pagination": {
    "page": 1,
    "pageSize": 50,
    "totalRecords": 240,
    "totalPages": 5
  },
  "audit_results": [
    {
      "companyName": "Stichting Kolom",
      "auditCode": "17301",
      "categoryName": "Financiën",
      "resultaat": "Voldoende",
      "date": "2023-12-14",
      "jaar": 2023
    }
  ]
}
```

---

## ⚙️ Example Integration Code (Node.js / Axios)

```js
import axios from 'axios';

const BASE_URL = 'https://icca-dashboard.maxapex.net/ords/icca/api';
const TOKEN_URL = 'https://icca-dashboard.maxapex.net/ords/icca/oauth/token';
const CLIENT_ID = ''; // send separtely
const CLIENT_SECRET = ''; // send separtely

async function fetchToken() {
  const credentials = Buffer.from(`${CLIENT_ID}:${CLIENT_SECRET}`).toString('base64');
  const response = await axios.post(TOKEN_URL, 'grant_type=client_credentials', {
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': `Basic ${credentials}`,
    }
  });
  return response.data.access_token;
}

async function getDashboardResults(filters) {
  const token = await fetchToken();
  const response = await axios.get(`${BASE_URL}/getDashboardResults`, {
    headers: { 'Authorization': `Bearer ${token}` },
    params: filters
  });
  return response.data;
}

// Example usage:
getDashboardResults({ company_name: 'Stichting Kolom', jaar: 2023, maand: 12 })
  .then(data => console.log(data))
  .catch(err => console.error(err));
```

---

## ⚠️ Notes
- API responses are paginated when data volume is large.
- Use `page` and `page_size` for navigation.
- All filters are optional and can be combined.
- Authentication tokens expire after 1 hour.

