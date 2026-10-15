# Deploying SwiftCart

This project uses a Next.js storefront, a Rust API, and MySQL. The recommended split is Vercel for the storefront and Railway for the Rust API and MySQL database.

## Database choice

For a clean demo deployment, create an empty Railway MySQL service. The Rust API runs the checked-in SQLx migrations at startup, which create and seed the project schema. This does not copy customer accounts, orders, wishlists, or other records from the developer's laptop.

To migrate existing records instead, export the local database and import it into the cloud database deliberately. Do not commit or publish the SQL dump; it may contain personal data.

## Railway: MySQL and Rust API

1. Create a Railway project and add a MySQL service.
2. Add a backend service from this GitHub repository, with its root directory set to `backend`. Railway will use `backend/Dockerfile`.
3. Set these variables on the backend service:
   - `DATABASE_URL`: reference the MySQL service's private `MYSQL_URL` variable.
   - `CORS_ORIGINS`: the exact deployed Vercel origin, without a trailing slash.
   - `OTP_HASH_SECRET`: a newly generated random secret of at least 32 characters.
   - `GMAIL_CLIENT_ID`, `GMAIL_CLIENT_SECRET`, and `GMAIL_REFRESH_TOKEN` for Gmail API email OTP. Keep these private. Gmail OAuth Testing mode expires authorization after 7 days. Alternatively, use `RESEND_API_KEY` and `RESEND_FROM`.
   - `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, and `TWILIO_FROM_NUMBER` if SMS OTP delivery is required.
4. Generate a public domain for the backend service. The service binds to Railway's `PORT` and exposes `/health` as its health endpoint.

Never put backend secrets in the frontend environment or in Git.

## Vercel: Next.js storefront

1. Import `Gojo-00/DBMS-Project` as a Vercel project.
2. Set the root directory to `DBMS-Project-E-Commerce-Website-Frontend/DBMS-Project-E-Commerce-Website-Frontend`.
3. Set `NEXT_PUBLIC_API_URL` to the backend's public HTTPS origin, without a trailing slash, then deploy.
4. Copy the final Vercel production origin into Railway's `CORS_ORIGINS` and redeploy the API.

The local `.env` files are intentionally excluded from Git. Configure production variables in the hosting dashboards and redeploy after changing them.
