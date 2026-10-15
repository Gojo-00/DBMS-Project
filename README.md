# SwiftCart — E-Commerce Storefront

SwiftCart is a full-stack online store built as a DBMS project. It combines a Next.js storefront, a Rust REST API, and a MySQL database. Customers can browse products, manage a wishlist, sign up or sign in with a one-time code, and place orders with delivery details.

## Features

- Product catalog with categories, search, stock counts, and product images
- Customer signup and sign-in with email OTP; optional SMS OTP through Twilio
- Wishlist and customer account details
- Checkout with delivery address and scheduled delivery information
- Order, payment-status, and delivery-status records
- Transactional order creation that checks and reduces inventory
- MySQL schema and demo catalog initialized by SQLx migrations
- Rust API health endpoint at `/health`

## Architecture

```text
Browser
  └── Next.js storefront
        └── Rust / Axum API
              ├── MySQL database
              ├── Gmail API or Resend for email OTP
              └── Twilio for optional SMS OTP
```

## Project layout

```text
backend/                                                        Rust API, migrations, Dockerfile
DBMS-Project-E-Commerce-Website-Frontend/
  DBMS-Project-E-Commerce-Website-Frontend/                     Next.js storefront
DEPLOYMENT.md                                                    Hosting notes
```

## Run locally

### Requirements

- MySQL 8 or compatible MySQL server
- Rust toolchain (edition 2024)
- Node.js and npm

### 1. Start the backend

Create a database named `EcommerceDB`, then open a terminal in `backend` and copy `.env.example` to `.env`. Set `DATABASE_URL` to your MySQL connection string and set a private `OTP_HASH_SECRET` with at least 32 characters. The API applies its migrations and seeds the demo catalog at startup.

```powershell
cd backend
cargo run
```

The API listens at `http://127.0.0.1:3000` by default. Check `http://127.0.0.1:3000/health`.

### 2. Start the storefront

Open a second terminal in `DBMS-Project-E-Commerce-Website-Frontend/DBMS-Project-E-Commerce-Website-Frontend`:

```powershell
npm install
npm run dev
```

Open `http://localhost:3001`. The storefront uses `http://127.0.0.1:3000` as its default API address. To change it, copy `.env.local.example` to `.env.local` and set `NEXT_PUBLIC_API_URL`.

## Email OTP configuration

The backend supports Gmail API over HTTPS and Resend over HTTPS. Gmail API takes priority when its OAuth variables are set; otherwise the backend uses `RESEND_API_KEY` and `RESEND_FROM`. Keep all provider credentials in the backend environment only.

For Gmail, generate OAuth credentials for the account that will send the OTPs:

1. In [Google Cloud Console](https://console.cloud.google.com/), create a project and enable the Gmail API.
2. Configure the OAuth consent screen as External. While it is in Testing, add the Gmail account that will send messages as a test user.
3. Create an OAuth Client ID with application type **Web application**. Add `https://developers.google.com/oauthplayground` as an authorized redirect URI.
4. Open [OAuth 2.0 Playground](https://developers.google.com/oauthplayground/), open its settings, select **Use your own OAuth credentials**, and enter that OAuth client ID and secret.
5. In Step 1, enter the scope `https://www.googleapis.com/auth/gmail.send`, authorize it using the sending Gmail account, then exchange the code in Step 2. Copy the refresh token shown there.
6. Add the three values below to the Railway backend service's Variables and redeploy it:

```env
GMAIL_CLIENT_ID=your_oauth_client_id
GMAIL_CLIENT_SECRET=your_oauth_client_secret
GMAIL_REFRESH_TOKEN=your_refresh_token
```

The Gmail account that granted OAuth access sends the message. The refresh token is sensitive: do not commit it, put it in a frontend variable, or share it in chat. Google OAuth projects left in Testing expire Gmail authorizations after 7 days, so you must reauthorize periodically. Google requires verification for public apps using sensitive Gmail scopes. Gmail API use currently has no extra API fee under Google's standard quota, but Gmail account sending limits apply. See [Gmail API authentication](https://developers.google.com/workspace/gmail/api/auth/web-server), [Gmail API scopes](https://developers.google.com/workspace/gmail/api/auth/scopes), and [usage limits](https://developers.google.com/workspace/gmail/api/reference/quota).

For quick Resend testing, set `RESEND_API_KEY`. Resend's onboarding sender is limited to verified recipients; sending to arbitrary customer addresses requires a verified sending domain. SMS OTP uses Twilio variables and may incur SMS charges.

## API overview

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/health` | Check API and database availability |
| `GET`, `POST` | `/api/categories` | List or create categories |
| `GET`, `POST` | `/api/products` | Search/filter products or create a product |
| `GET`, `PUT`, `DELETE` | `/api/products/{product_id}` | Read, update, or delete a product |
| `POST` | `/api/auth/request-otp` | Request an email or SMS code |
| `POST` | `/api/auth/verify-otp` | Verify a code and create or sign in to an account |
| `GET`, `POST` | `/api/customers/{customer_id}/wishlist` | Read or add wishlist items |
| `DELETE` | `/api/customers/{customer_id}/wishlist/{product_id}` | Remove a wishlist item |
| `POST` | `/api/orders` | Place an order and reduce stock transactionally |
| `GET` | `/api/orders/{order_id}` | Read order, items, payment, and delivery |
| `GET` | `/api/customers/{customer_id}/orders` | List a customer's orders |
| `PATCH` | `/api/orders/{order_id}/payment` | Update payment status |
| `PATCH` | `/api/orders/{order_id}/delivery` | Update delivery status |
| `GET` | `/api/reports/summary` | Read customer, product, order, and sales totals |

Checkout records payment information and order status; it does not connect to a real payment processor.

## Deploy

See [DEPLOYMENT.md](DEPLOYMENT.md) for the Railway and Vercel setup, environment variables, service root directories, and CORS configuration. Never commit `.env`, `.env.local`, database exports, OAuth credentials, or provider API keys.

## Database tables

The migrations create and seed `Customer`, `Category`, `Product`, `Orders`, `Order_Item`, `Payment`, `Delivery`, and `Wishlist`. OTP challenges are stored temporarily in `OtpChallenge`; codes are hashed and expire after five minutes.
