# E-Commerce Rust Backend

Axum HTTP API backed by the project's MySQL `EcommerceDB` schema. SQLx runs the ID-generation migration on startup so API-created records receive primary keys automatically.

## Run locally

Keep the database credentials in `.env` (do not commit that file):

```env
DATABASE_URL=mysql://root:your_password@localhost:3306/EcommerceDB
```

Start the API from this directory:

```powershell
cargo run
```

The server listens at `http://127.0.0.1:3000`. CORS is permissive for local frontend integration. This API is intended for the local class project.

### OTP signup/sign-in setup

Copy `.env.example` to `.env`, keep `.env` private, and set `OTP_HASH_SECRET` to a random value of at least 32 characters. Email OTPs use Gmail API over HTTPS when `GMAIL_CLIENT_ID`, `GMAIL_CLIENT_SECRET`, and `GMAIL_REFRESH_TOKEN` are set. The Gmail account that authorized OAuth sends the message. Use the `https://www.googleapis.com/auth/gmail.send` scope. Keep OAuth credentials private; Google OAuth projects in Testing mode expire Gmail authorization after 7 days. If Gmail OAuth variables are absent, the API falls back to Resend (`RESEND_API_KEY`); arbitrary recipients require a verified Resend sending domain. For phone OTP, configure a Twilio account and sender number in the `TWILIO_*` variables. Twilio trial accounts may only send to verified recipient numbers, and SMS fees may apply.

The API applies its OTP table migration at startup. Codes expire in 5 minutes, are stored as hashes, allow up to 5 verification attempts, and are limited to 3 requests per contact every 15 minutes.

## Endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | API and database health |
| GET, POST | `/api/categories` | List or create categories |
| GET, POST | `/api/products` | Search/filter products or create a product |
| GET, PUT, DELETE | `/api/products/{product_id}` | Read, update, or delete a product |
| POST | `/api/customers` | Create a customer |
| POST | `/api/auth/request-otp` | Request an email or SMS code for signup/sign-in |
| POST | `/api/auth/verify-otp` | Verify the code and return the customer account |
| GET, PUT | `/api/customers/{customer_id}` | Read or update a customer |
| GET, POST | `/api/customers/{customer_id}/wishlist` | Read wishlist or add a product |
| DELETE | `/api/customers/{customer_id}/wishlist/{product_id}` | Remove a wishlist item |
| POST | `/api/orders` | Place an order; checks and reduces stock in one transaction |
| GET | `/api/orders/{order_id}` | Read order, items, payment, and delivery |
| GET | `/api/customers/{customer_id}/orders` | List a customer's orders |
| PATCH | `/api/orders/{order_id}/payment` | Update payment status record |
| PATCH | `/api/orders/{order_id}/delivery` | Update delivery status and completion date |
| GET | `/api/reports/summary` | Customer, product, order, revenue, and sales totals |

Product search accepts `?search=book` and category filtering accepts `?category_id=3` (they can be combined). Order creation records a pending payment and processing delivery; it does not connect to a real payment provider.

### Example order request

```json
{
  "customer_id": 1,
  "items": [
    { "product_id": 101, "quantity": 1 },
    { "product_id": 103, "quantity": 2 }
  ],
  "payment_method": "UPI",
  "delivery_address": "Mumbai",
  "scheduled_delivery_date": "2026-10-20",
  "scheduled_delivery_time": "14:00:00"
}
```

Payment statuses accepted: `Pending`, `Paid`, `Failed`, `Refunded`. Delivery statuses accepted: `Processing`, `In Transit`, `Delivered`, `Cancelled`.
