# SwiftCart frontend

This Next.js storefront reads categories and inventory from the Rust API and saves customer wishlists and orders to the MySQL database through that API.

## Run locally

1. Start MySQL and the Rust backend from `DBMS-Project/backend` with `cargo run` (API: `http://127.0.0.1:3000`).
2. From this frontend directory, install dependencies once with `npm install`.
3. Start the storefront with `npm run dev` (website: `http://localhost:3001`).

The frontend defaults to `http://127.0.0.1:3000` for its API. To override it, create `.env.local` from `.env.local.example` and set `NEXT_PUBLIC_API_URL`.

Checkout creates or updates a guest customer record in the database using the name and optional email entered in the cart. It creates an order with Cash on Delivery; the project API does not connect to a payment provider.
