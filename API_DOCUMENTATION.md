# HomeStock — REST API Documentation

Base URL: `http://localhost:8080/api/v1`  
Interactive OpenAPI / Swagger UI: `http://localhost:8080/swagger-ui.html`  
Raw OpenAPI JSON: `http://localhost:8080/v3/api-docs`

---

## 1. Authentication & Security

All private endpoints require a Bearer token in the HTTP Authorization header:
```http
Authorization: Bearer <access_token>
```

### Response Wrapper Format
All responses conform to a unified standard structure:
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": { ... },
  "timestamp": "2026-09-06T18:50:00Z"
}
```

---

## 2. API Endpoints Reference

### 2.1 Authentication (`/api/v1/auth`)

| Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :--- |
| `POST` | `/auth/register` | Register a new user account | Public |
| `POST` | `/auth/login` | Login with email and password | Public |
| `POST` | `/auth/refresh` | Obtain a new access token using a refresh token | Public |
| `POST` | `/auth/logout` | Revoke active refresh token | Authenticated |

#### Register Request Body:
```json
{
  "fullName": "Priya Sharma",
  "email": "priya@example.com",
  "password": "Password123!",
  "phoneNumber": "+91 9876543210"
}
```

---

### 2.2 Homes & Household Members (`/api/v1/homes`)

| Method | Endpoint | Description | Roles |
| :--- | :--- | :--- | :--- |
| `GET` | `/homes` | List all homes current user is a member of | Any |
| `POST` | `/homes` | Create a new home (creator becomes `OWNER`) | Any |
| `POST` | `/homes/join` | Join home using 8-character invite code | Any |
| `GET` | `/homes/{homeId}` | Get details of a specific home | `MEMBER`+ |
| `PUT` | `/homes/{homeId}` | Update home name / settings | `ADMIN`, `OWNER` |
| `GET` | `/homes/{homeId}/members` | List members of a home | `MEMBER`+ |
| `PUT` | `/homes/{homeId}/members/{userId}/role` | Change member role (`ADMIN`, `MEMBER`, `VIEWER`) | `OWNER` |
| `DELETE`| `/homes/{homeId}/members/{userId}` | Remove member from home | `ADMIN`, `OWNER` |

---

### 2.3 Product Categories (`/api/v1/homes/{homeId}/categories`)

| Method | Endpoint | Description | Roles |
| :--- | :--- | :--- | :--- |
| `GET` | `/homes/{homeId}/categories` | Get all product categories for a home | `MEMBER`+ |
| `POST` | `/homes/{homeId}/categories` | Create custom category | `ADMIN`, `OWNER` |

---

### 2.4 Household Inventory (`/api/v1/homes/{homeId}/items`)

| Method | Endpoint | Description | Roles |
| :--- | :--- | :--- | :--- |
| `GET` | `/homes/{homeId}/items` | List & search items (supports `categoryId`, `query`, `page`, `size`) | `MEMBER`+ |
| `GET` | `/homes/{homeId}/items/{itemId}` | Get item details and expiry status | `MEMBER`+ |
| `POST` | `/homes/{homeId}/items` | Create new inventory item | `MEMBER`+ |
| `PUT` | `/homes/{homeId}/items/{itemId}` | Update inventory item details | `MEMBER`+ |
| `POST` | `/homes/{homeId}/items/{itemId}/stock`| Adjust stock (+/- delta) with audit reason | `MEMBER`+ |
| `GET` | `/homes/{homeId}/items/{itemId}/transactions` | View audit trail of stock adjustments | `MEMBER`+ |
| `POST` | `/homes/{homeId}/items/{itemId}/image`| Upload photo for item | `MEMBER`+ |
| `DELETE`| `/homes/{homeId}/items/{itemId}` | Soft delete inventory item | `ADMIN`, `OWNER` |

#### Create Item Request Body:
```json
{
  "name": "Organic Whole Milk",
  "categoryId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "quantity": 1.0,
  "minimumQuantity": 2.0,
  "unit": "liters",
  "purchasePrice": 65.0,
  "storageLocation": "Refrigerator - Top Shelf",
  "expiryDate": "2026-09-12",
  "notes": "Always buy full cream"
}
```

---

### 2.5 Shared Shopping List (`/api/v1/homes/{homeId}/shopping-lists`)

| Method | Endpoint | Description | Roles |
| :--- | :--- | :--- | :--- |
| `GET` | `/homes/{homeId}/shopping-lists/default` | Get active shopping list (with pending & completed items) | `MEMBER`+ |
| `POST` | `/homes/{homeId}/shopping-lists/{listId}/items` | Add item manually to shopping list | `MEMBER`+ |
| `PUT` | `/homes/{homeId}/shopping-lists/{listId}/items/{itemId}/toggle` | Check or uncheck shopping item | `MEMBER`+ |
| `DELETE`| `/homes/{homeId}/shopping-lists/{listId}/items/{itemId}` | Remove item from shopping list | `MEMBER`+ |
| `POST` | `/homes/{homeId}/shopping-lists/{listId}/clear-completed` | Clear all checked items | `MEMBER`+ |

---

### 2.6 Purchases & Auto-Restock (`/api/v1/homes/{homeId}/purchases`)

| Method | Endpoint | Description | Roles |
| :--- | :--- | :--- | :--- |
| `POST` | `/homes/{homeId}/purchases` | Record grocery run, atomically update stock & clear shopping items | `MEMBER`+ |
| `GET` | `/homes/{homeId}/purchases` | List purchase history with receipt totals and pagination | `MEMBER`+ |
| `GET` | `/homes/{homeId}/purchases/{purchaseId}` | Get single purchase details with line items | `MEMBER`+ |

#### Record Purchase Request Body:
```json
{
  "storeId": "Optional store UUID",
  "purchaseDate": "2026-09-06",
  "totalAmount": 450.0,
  "currency": "INR",
  "notes": "Weekly supermarket run",
  "items": [
    {
      "inventoryItemId": "457c3c39-8b9e-438c-8bcf-eba43f91255c",
      "itemName": "Basmati Rice",
      "quantity": 5.0,
      "unit": "kg",
      "unitPrice": 90.0,
      "totalPrice": 450.0
    }
  ]
}
```

---

### 2.7 Consumer Dashboard & Recommendations (`/api/v1/homes/{homeId}/dashboard`)

| Method | Endpoint | Description | Roles |
| :--- | :--- | :--- | :--- |
| `GET` | `/homes/{homeId}/dashboard` | Summary counts (total, low stock, out of stock, expiring, monthly spend) | `MEMBER`+ |
| `GET` | `/homes/{homeId}/dashboard/what-do-i-need` | Algorithmic restock recommendations categorized by urgency (`URGENT`, `SOON`, `OPTIONAL`) | `MEMBER`+ |

---

### 2.8 Spending Analytics (`/api/v1/homes/{homeId}/analytics`)

| Method | Endpoint | Description | Roles |
| :--- | :--- | :--- | :--- |
| `GET` | `/homes/{homeId}/analytics?months=6` | Category-wise expenditure breakdown, monthly trend, most bought items | `MEMBER`+ |

---

### 2.9 Push & In-App Notifications (`/api/v1/notifications`)

| Method | Endpoint | Description | Roles |
| :--- | :--- | :--- | :--- |
| `GET` | `/notifications` | List notifications for the authenticated user | Any |
| `PUT` | `/notifications/{id}/read` | Mark specific notification as read | Any |
| `PUT` | `/notifications/read-all` | Mark all notifications as read | Any |
