use crate::{
    error::{ApiError, ApiResult},
    models::{
        AddWishlistItem, ApiMessage, Category, CreateOrder, Customer, CustomerInput, DeliveryInfo,
        OrderDetail, OrderLine, OrderSummary, PaymentInfo, Product, ProductFilter, ProductInput,
        StatusUpdate, WishlistItem,
    },
};
use axum::{
    Json, Router,
    extract::{Path, Query, State},
    http::StatusCode,
    routing::{delete, get, patch, post},
};
use lettre::{
    AsyncSmtpTransport, AsyncTransport, Message, Tokio1Executor,
    message::Mailbox,
    transport::smtp::authentication::Credentials,
};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use sha2::{Digest, Sha256};
use sqlx::{MySqlPool, QueryBuilder, Row, mysql::MySql};
use std::collections::HashSet;
use std::time::Duration;
use uuid::Uuid;

#[derive(Clone)]
pub struct AppState {
    pub pool: MySqlPool,
}

pub fn router(state: AppState) -> Router {
    Router::new()
        .route("/health", get(health))
        .route(
            "/api/categories",
            get(list_categories).post(create_category),
        )
        .route(
            "/api/categories/{category_id}",
            get(get_category)
                .put(update_category)
                .delete(delete_category),
        )
        .route("/api/products", get(list_products).post(create_product))
        .route(
            "/api/products/{product_id}",
            get(get_product).put(update_product).delete(delete_product),
        )
        .route("/api/customers", post(create_customer))
        .route("/api/auth/request-otp", post(request_otp))
        .route("/api/auth/verify-otp", post(verify_otp))
        .route(
            "/api/customers/{customer_id}",
            get(get_customer).put(update_customer),
        )
        .route(
            "/api/customers/{customer_id}/wishlist",
            get(get_wishlist).post(add_wishlist_item),
        )
        .route(
            "/api/customers/{customer_id}/wishlist/{product_id}",
            delete(remove_wishlist_item),
        )
        .route("/api/orders", post(create_order))
        .route("/api/orders/{order_id}", get(get_order))
        .route(
            "/api/customers/{customer_id}/orders",
            get(list_customer_orders),
        )
        .route(
            "/api/orders/{order_id}/payment",
            patch(update_payment_status),
        )
        .route(
            "/api/orders/{order_id}/delivery",
            patch(update_delivery_status),
        )
        .route("/api/reports/summary", get(report_summary))
        .with_state(state)
}

#[derive(Debug, Deserialize, Clone, Copy)]
#[serde(rename_all = "snake_case")]
enum AuthPurpose {
    Signup,
    Signin,
}

impl AuthPurpose {
    fn as_str(&self) -> &'static str {
        match self {
            Self::Signup => "signup",
            Self::Signin => "signin",
        }
    }
}

#[derive(Debug, Deserialize)]
struct OtpRequest {
    contact: String,
    name: Option<String>,
    purpose: AuthPurpose,
}

#[derive(Debug, Deserialize)]
struct OtpVerification {
    challenge_id: String,
    code: String,
}

#[derive(Debug, Serialize)]
struct OtpRequestResponse {
    challenge_id: String,
    expires_in_seconds: u32,
    message: &'static str,
}

#[derive(Debug, Serialize)]
struct AuthResponse {
    customer: Customer,
}

#[derive(Debug, Clone, Copy)]
enum OtpChannel {
    Email,
    Phone,
}

impl OtpChannel {
    fn as_str(self) -> &'static str {
        match self {
            Self::Email => "email",
            Self::Phone => "phone",
        }
    }
}

fn normalize_contact(value: &str) -> ApiResult<(String, OtpChannel)> {
    let value = value.trim();
    if value.contains('@') {
        let mut parts = value.split('@');
        let local = parts.next().unwrap_or_default();
        let domain = parts.next().unwrap_or_default();
        if local.is_empty()
            || domain.is_empty()
            || parts.next().is_some()
            || !domain.contains('.')
            || domain.starts_with('.')
            || domain.ends_with('.')
            || value.chars().any(char::is_whitespace)
        {
            return Err(ApiError::bad_request("Enter a valid email address"));
        }
        return Ok((value.to_ascii_lowercase(), OtpChannel::Email));
    }

    if value.chars().any(|c| !(c.is_ascii_digit() || matches!(c, '+' | '-' | '(' | ')' | ' ')))
        || value.matches('+').count() > 1
        || (value.contains('+') && !value.starts_with('+'))
    {
        return Err(ApiError::bad_request("Enter a valid phone number"));
    }
    let digits: String = value.chars().filter(char::is_ascii_digit).collect();
    let phone = if value.starts_with('+') {
        format!("+{digits}")
    } else if digits.len() == 10 {
        // The storefront is configured for India; allow the common 10-digit form.
        format!("+91{digits}")
    } else {
        return Err(ApiError::bad_request(
            "Enter a phone number with country code, such as +91 98765 43210",
        ));
    };
    let national_digits = phone.trim_start_matches('+');
    if !(8..=15).contains(&national_digits.len()) || !national_digits.chars().all(|c| c.is_ascii_digit()) {
        return Err(ApiError::bad_request("Enter a valid phone number"));
    }
    Ok((phone, OtpChannel::Phone))
}

fn otp_hash(challenge_id: &str, code: &str) -> ApiResult<String> {
    let secret = std::env::var("OTP_HASH_SECRET").map_err(|_| {
        ApiError::service_unavailable("OTP_HASH_SECRET is not configured on the backend")
    })?;
    if secret.trim().len() < 32 {
        return Err(ApiError::service_unavailable(
            "OTP_HASH_SECRET must be at least 32 characters",
        ));
    }
    let digest = Sha256::digest(format!("{}:{challenge_id}:{code}", secret.trim()).as_bytes());
    Ok(format!("{digest:x}"))
}

async fn customer_for_contact(
    pool: &MySqlPool,
    contact: &str,
    channel: OtpChannel,
) -> Result<Option<Customer>, sqlx::Error> {
    let query = match channel {
        OtpChannel::Email => {
            "SELECT customer_id, name, email, phone, address FROM Customer WHERE LOWER(email) = ? ORDER BY customer_id LIMIT 1"
        }
        OtpChannel::Phone => {
            "SELECT customer_id, name, email, phone, address FROM Customer WHERE phone = ? ORDER BY customer_id LIMIT 1"
        }
    };
    sqlx::query_as::<_, Customer>(query)
        .bind(contact)
        .fetch_optional(pool)
        .await
}

async fn deliver_otp(contact: &str, channel: OtpChannel, code: &str) -> ApiResult<()> {
    match channel {
        OtpChannel::Email => {
            let username = std::env::var("SMTP_USERNAME").ok().filter(|v| !v.trim().is_empty())
                .ok_or_else(|| ApiError::service_unavailable("Email OTP is not configured: set SMTP_USERNAME and SMTP_APP_PASSWORD"))?;
            let password = std::env::var("SMTP_APP_PASSWORD").ok().filter(|v| !v.trim().is_empty())
                .ok_or_else(|| ApiError::service_unavailable("Email OTP is not configured: set SMTP_APP_PASSWORD"))?;
            let from_address = std::env::var("SMTP_FROM").unwrap_or_else(|_| username.clone());
            let host = std::env::var("SMTP_HOST").unwrap_or_else(|_| "smtp.gmail.com".to_string());
            let from: Mailbox = format!("SwiftCart <{}>", from_address.trim())
                .parse()
                .map_err(|_| ApiError::service_unavailable("SMTP_FROM is not a valid email address"))?;
            let to: Mailbox = contact.parse()
                .map_err(|_| ApiError::bad_request("Enter a valid email address"))?;
            let message = Message::builder()
                .from(from)
                .to(to)
                .subject("Your SwiftCart verification code")
                .body(format!("Your SwiftCart verification code is {code}. It expires in 5 minutes. Do not share this code."))
                .map_err(|_| ApiError::service_unavailable("Could not prepare the verification email"))?;
            let mailer = AsyncSmtpTransport::<Tokio1Executor>::starttls_relay(host.trim())
                .map_err(|_| ApiError::service_unavailable("Could not configure the email server"))?
                .credentials(Credentials::new(username.trim().to_string(), password.split_whitespace().collect()))
                .timeout(Some(Duration::from_secs(12)))
                .build();
            mailer.send(message).await.map_err(|error| {
                eprintln!("Email OTP delivery failed: {error}");
                ApiError::bad_gateway("Email provider could not deliver the verification code")
            })?;
        }
        OtpChannel::Phone => {
            let sid = std::env::var("TWILIO_ACCOUNT_SID").ok().filter(|v| !v.trim().is_empty())
                .ok_or_else(|| ApiError::service_unavailable("SMS OTP is not configured: set Twilio credentials"))?;
            let token = std::env::var("TWILIO_AUTH_TOKEN").ok().filter(|v| !v.trim().is_empty())
                .ok_or_else(|| ApiError::service_unavailable("SMS OTP is not configured: set Twilio credentials"))?;
            let from = std::env::var("TWILIO_FROM_NUMBER").ok().filter(|v| !v.trim().is_empty())
                .ok_or_else(|| ApiError::service_unavailable("SMS OTP is not configured: set TWILIO_FROM_NUMBER"))?;
            let url = format!("https://api.twilio.com/2010-04-01/Accounts/{}/Messages.json", sid.trim());
            let response = reqwest::Client::new()
                .post(url)
                .basic_auth(sid.trim(), Some(token.trim()))
                .form(&[
                    ("To", contact),
                    ("From", from.trim()),
                    ("Body", &format!("Your SwiftCart verification code is {code}. It expires in 5 minutes. Do not share this code.")),
                ])
                .timeout(Duration::from_secs(15))
                .send()
                .await
                .map_err(|_| ApiError::bad_gateway("Could not reach the SMS provider"))?;
            if !response.status().is_success() {
                eprintln!("SMS OTP provider returned HTTP {}", response.status());
                return Err(ApiError::bad_gateway("SMS provider could not deliver the verification code"));
            }
        }
    }
    Ok(())
}

async fn request_otp(
    State(state): State<AppState>,
    Json(body): Json<OtpRequest>,
) -> ApiResult<(StatusCode, Json<OtpRequestResponse>)> {
    let (contact, channel) = normalize_contact(&body.contact)?;
    let name = body.name.as_deref().unwrap_or_default().trim();
    if matches!(body.purpose, AuthPurpose::Signup) && (name.is_empty() || name.len() > 120) {
        return Err(ApiError::bad_request("Enter your name (up to 120 characters) to sign up"));
    }

    let existing = customer_for_contact(&state.pool, &contact, channel).await?;
    match (&body.purpose, &existing) {
        (AuthPurpose::Signup, Some(_)) => {
            return Err(ApiError::conflict("An account already uses this contact. Sign in instead."));
        }
        (AuthPurpose::Signin, None) => {
            return Err(ApiError::not_found("No account uses this contact. Sign up first."));
        }
        _ => {}
    }

    sqlx::query("DELETE FROM OtpChallenge WHERE expires_at < DATE_SUB(NOW(), INTERVAL 1 DAY)")
        .execute(&state.pool)
        .await?;
    let count: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM OtpChallenge WHERE contact = ? AND created_at > DATE_SUB(NOW(), INTERVAL 15 MINUTE)",
    )
    .bind(&contact)
    .fetch_one(&state.pool)
    .await?;
    if count >= 3 {
        return Err(ApiError::too_many_requests("Too many codes requested. Wait 15 minutes and try again."));
    }

    let challenge_id = Uuid::new_v4().to_string();
    let code = format!("{:06}", Uuid::new_v4().as_u128() % 1_000_000);
    let code_hash = otp_hash(&challenge_id, &code)?;
    sqlx::query(
        "INSERT INTO OtpChallenge (challenge_id, contact, channel, purpose, customer_name, code_hash, expires_at) VALUES (?, ?, ?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL 5 MINUTE))",
    )
    .bind(&challenge_id)
    .bind(&contact)
    .bind(channel.as_str())
    .bind(body.purpose.as_str())
    .bind(if matches!(body.purpose, AuthPurpose::Signup) { Some(name) } else { None })
    .bind(&code_hash)
    .execute(&state.pool)
    .await?;

    if let Err(error) = deliver_otp(&contact, channel, &code).await {
        let _ = sqlx::query("DELETE FROM OtpChallenge WHERE challenge_id = ?")
            .bind(&challenge_id)
            .execute(&state.pool)
            .await;
        return Err(error);
    }

    Ok((StatusCode::ACCEPTED, Json(OtpRequestResponse {
        challenge_id,
        expires_in_seconds: 300,
        message: "Verification code sent",
    })))
}

async fn verify_otp(
    State(state): State<AppState>,
    Json(body): Json<OtpVerification>,
) -> ApiResult<Json<AuthResponse>> {
    if body.code.len() != 6 || !body.code.chars().all(|c| c.is_ascii_digit()) {
        return Err(ApiError::bad_request("Enter the 6-digit verification code"));
    }
    let expected_hash = otp_hash(&body.challenge_id, &body.code)?;
    let mut tx = state.pool.begin().await?;
    let row = sqlx::query(
        "SELECT contact, channel, purpose, customer_name, code_hash, attempt_count, (expires_at <= NOW()) AS expired, used_at IS NOT NULL AS used FROM OtpChallenge WHERE challenge_id = ? FOR UPDATE",
    )
    .bind(&body.challenge_id)
    .fetch_optional(&mut *tx)
    .await?
    .ok_or_else(|| ApiError::bad_request("That code is invalid or has expired. Request a new code."))?;
    let contact: String = row.try_get("contact")?;
    let channel_name: String = row.try_get("channel")?;
    let purpose: String = row.try_get("purpose")?;
    let customer_name: Option<String> = row.try_get("customer_name")?;
    let stored_hash: String = row.try_get("code_hash")?;
    let attempt_count: u8 = row.try_get("attempt_count")?;
    let expired: bool = row.try_get("expired")?;
    let used: bool = row.try_get("used")?;

    if used {
        return Err(ApiError::bad_request("That code has already been used. Request a new code."));
    }
    if expired {
        tx.commit().await?;
        return Err(ApiError::bad_request("That code has expired. Request a new code."));
    }
    if attempt_count >= 5 {
        sqlx::query("UPDATE OtpChallenge SET used_at = NOW() WHERE challenge_id = ?")
            .bind(&body.challenge_id).execute(&mut *tx).await?;
        tx.commit().await?;
        return Err(ApiError::too_many_requests("Too many incorrect codes. Request a new one."));
    }
    let mut diff = 0u8;
    for (a, b) in expected_hash.bytes().zip(stored_hash.bytes()) { diff |= a ^ b; }
    if diff != 0 {
        sqlx::query("UPDATE OtpChallenge SET attempt_count = attempt_count + 1 WHERE challenge_id = ?")
            .bind(&body.challenge_id).execute(&mut *tx).await?;
        tx.commit().await?;
        return Err(ApiError::bad_request("The verification code is incorrect"));
    }

    let channel = match channel_name.as_str() {
        "email" => OtpChannel::Email,
        "phone" => OtpChannel::Phone,
        _ => return Err(ApiError::bad_request("Invalid verification challenge")),
    };
    let customer = if purpose == "signup" {
        let name = customer_name.filter(|value| !value.trim().is_empty())
            .ok_or_else(|| ApiError::bad_request("The signup name is missing. Start signup again."))?;
        if customer_for_contact_tx(&mut tx, &contact, channel).await?.is_some() {
            sqlx::query("UPDATE OtpChallenge SET used_at = NOW() WHERE challenge_id = ?")
                .bind(&body.challenge_id).execute(&mut *tx).await?;
            tx.commit().await?;
            return Err(ApiError::conflict("An account already uses this contact. Sign in instead."));
        }
        let email = matches!(channel, OtpChannel::Email).then_some(contact.as_str());
        let phone = matches!(channel, OtpChannel::Phone).then_some(contact.as_str());
        let inserted = sqlx::query("INSERT INTO Customer (name, email, phone, address) VALUES (?, ?, ?, '')")
            .bind(name.trim()).bind(email).bind(phone).execute(&mut *tx).await?;
        let id = checked_id(inserted.last_insert_id())?;
        customer_by_id_tx(&mut tx, id).await?
    } else if purpose == "signin" {
        customer_for_contact_tx(&mut tx, &contact, channel).await?
            .ok_or_else(|| ApiError::not_found("No account uses this contact. Sign up first."))?
    } else {
        return Err(ApiError::bad_request("Invalid verification challenge"));
    };

    sqlx::query("UPDATE OtpChallenge SET used_at = NOW() WHERE challenge_id = ?")
        .bind(&body.challenge_id).execute(&mut *tx).await?;
    tx.commit().await?;
    Ok(Json(AuthResponse { customer }))
}

async fn customer_for_contact_tx(
    tx: &mut sqlx::Transaction<'_, MySql>,
    contact: &str,
    channel: OtpChannel,
) -> Result<Option<Customer>, sqlx::Error> {
    let query = match channel {
        OtpChannel::Email => "SELECT customer_id, name, email, phone, address FROM Customer WHERE LOWER(email) = ? ORDER BY customer_id LIMIT 1",
        OtpChannel::Phone => "SELECT customer_id, name, email, phone, address FROM Customer WHERE phone = ? ORDER BY customer_id LIMIT 1",
    };
    sqlx::query_as::<_, Customer>(query).bind(contact).fetch_optional(&mut **tx).await
}

async fn customer_by_id_tx(
    tx: &mut sqlx::Transaction<'_, MySql>,
    customer_id: i32,
) -> ApiResult<Customer> {
    sqlx::query_as::<_, Customer>(
        "SELECT customer_id, name, email, phone, address FROM Customer WHERE customer_id = ?",
    )
    .bind(customer_id)
    .fetch_optional(&mut **tx)
    .await?
    .ok_or_else(|| ApiError::not_found("Customer not found after signup"))
}

async fn health(State(state): State<AppState>) -> ApiResult<Json<Value>> {
    sqlx::query("SELECT 1").execute(&state.pool).await?;
    Ok(Json(json!({ "status": "ok", "database": "connected" })))
}

async fn list_categories(State(state): State<AppState>) -> ApiResult<Json<Vec<Category>>> {
    let rows = sqlx::query_as::<_, Category>(
        "SELECT category_id, category_name, description FROM Category ORDER BY category_name",
    )
    .fetch_all(&state.pool)
    .await?;
    Ok(Json(rows))
}

async fn create_category(
    State(state): State<AppState>,
    Json(body): Json<CategoryInput>,
) -> ApiResult<(StatusCode, Json<Category>)> {
    require_text(&body.category_name, "category_name")?;
    let result = sqlx::query("INSERT INTO Category (category_name, description) VALUES (?, ?)")
        .bind(body.category_name.trim())
        .bind(body.description)
        .execute(&state.pool)
        .await?;
    let id = checked_id(result.last_insert_id())?;
    Ok((
        StatusCode::CREATED,
        Json(category_by_id(&state.pool, id).await?),
    ))
}

async fn get_category(
    State(state): State<AppState>,
    Path(category_id): Path<i32>,
) -> ApiResult<Json<Category>> {
    Ok(Json(category_by_id(&state.pool, category_id).await?))
}

async fn update_category(
    State(state): State<AppState>,
    Path(category_id): Path<i32>,
    Json(body): Json<CategoryInput>,
) -> ApiResult<Json<Category>> {
    require_text(&body.category_name, "category_name")?;
    sqlx::query("UPDATE Category SET category_name = ?, description = ? WHERE category_id = ?")
        .bind(body.category_name.trim())
        .bind(body.description)
        .bind(category_id)
        .execute(&state.pool)
        .await?;
    Ok(Json(category_by_id(&state.pool, category_id).await?))
}

async fn delete_category(
    State(state): State<AppState>,
    Path(category_id): Path<i32>,
) -> ApiResult<StatusCode> {
    let result = sqlx::query("DELETE FROM Category WHERE category_id = ?")
        .bind(category_id)
        .execute(&state.pool)
        .await?;
    if result.rows_affected() == 0 {
        return Err(ApiError::not_found("Category not found"));
    }
    Ok(StatusCode::NO_CONTENT)
}

#[derive(serde::Deserialize)]
struct CategoryInput {
    category_name: String,
    description: Option<String>,
}

async fn list_products(
    State(state): State<AppState>,
    Query(filter): Query<ProductFilter>,
) -> ApiResult<Json<Vec<Product>>> {
    let mut query = QueryBuilder::<MySql>::new(
        "SELECT p.product_id, p.product_name, CAST(p.price AS DOUBLE) AS price, \
         p.stock_quantity, p.category_id, c.category_name, p.image_url \
         FROM Product p LEFT JOIN Category c ON c.category_id = p.category_id WHERE 1=1",
    );
    if let Some(category_id) = filter.category_id {
        query.push(" AND p.category_id = ").push_bind(category_id);
    }
    if let Some(search) = filter.search.filter(|value| !value.trim().is_empty()) {
        query
            .push(" AND p.product_name LIKE ")
            .push_bind(format!("%{}%", search.trim()));
    }
    query.push(" ORDER BY p.product_id");
    let rows = query
        .build_query_as::<Product>()
        .fetch_all(&state.pool)
        .await?;
    Ok(Json(rows))
}

async fn get_product(
    State(state): State<AppState>,
    Path(product_id): Path<i32>,
) -> ApiResult<Json<Product>> {
    Ok(Json(product_by_id(&state.pool, product_id).await?))
}

async fn create_product(
    State(state): State<AppState>,
    Json(body): Json<ProductInput>,
) -> ApiResult<(StatusCode, Json<Product>)> {
    validate_product(&body)?;
    let result = sqlx::query(
        "INSERT INTO Product (product_name, price, stock_quantity, category_id, image_url) VALUES (?, ?, ?, ?, ?)",
    )
    .bind(body.product_name.trim())
    .bind(body.price)
    .bind(body.stock_quantity)
    .bind(body.category_id)
    .bind(body.image_url.as_deref())
    .execute(&state.pool)
    .await?;
    let id = checked_id(result.last_insert_id())?;
    Ok((
        StatusCode::CREATED,
        Json(product_by_id(&state.pool, id).await?),
    ))
}

async fn update_product(
    State(state): State<AppState>,
    Path(product_id): Path<i32>,
    Json(body): Json<ProductInput>,
) -> ApiResult<Json<Product>> {
    validate_product(&body)?;
    sqlx::query(
        "UPDATE Product SET product_name = ?, price = ?, stock_quantity = ?, category_id = ?, image_url = ? WHERE product_id = ?",
    )
    .bind(body.product_name.trim())
    .bind(body.price)
    .bind(body.stock_quantity)
    .bind(body.category_id)
    .bind(body.image_url.as_deref())
    .bind(product_id)
    .execute(&state.pool)
    .await?;
    Ok(Json(product_by_id(&state.pool, product_id).await?))
}

async fn delete_product(
    State(state): State<AppState>,
    Path(product_id): Path<i32>,
) -> ApiResult<StatusCode> {
    let result = sqlx::query("DELETE FROM Product WHERE product_id = ?")
        .bind(product_id)
        .execute(&state.pool)
        .await?;
    if result.rows_affected() == 0 {
        return Err(ApiError::not_found("Product not found"));
    }
    Ok(StatusCode::NO_CONTENT)
}

async fn create_customer(
    State(state): State<AppState>,
    Json(body): Json<CustomerInput>,
) -> ApiResult<(StatusCode, Json<Customer>)> {
    validate_customer(&body)?;
    let result =
        sqlx::query("INSERT INTO Customer (name, email, phone, address) VALUES (?, ?, ?, ?)")
            .bind(body.name.trim())
            .bind(body.email)
            .bind(body.phone)
            .bind(body.address.trim())
            .execute(&state.pool)
            .await?;
    let id = checked_id(result.last_insert_id())?;
    Ok((
        StatusCode::CREATED,
        Json(customer_by_id(&state.pool, id).await?),
    ))
}

async fn get_customer(
    State(state): State<AppState>,
    Path(customer_id): Path<i32>,
) -> ApiResult<Json<Customer>> {
    Ok(Json(customer_by_id(&state.pool, customer_id).await?))
}

async fn update_customer(
    State(state): State<AppState>,
    Path(customer_id): Path<i32>,
    Json(body): Json<CustomerInput>,
) -> ApiResult<Json<Customer>> {
    validate_customer(&body)?;
    sqlx::query(
        "UPDATE Customer SET name = ?, email = ?, phone = ?, address = ? WHERE customer_id = ?",
    )
    .bind(body.name.trim())
    .bind(body.email)
    .bind(body.phone)
    .bind(body.address.trim())
    .bind(customer_id)
    .execute(&state.pool)
    .await?;
    Ok(Json(customer_by_id(&state.pool, customer_id).await?))
}

async fn get_wishlist(
    State(state): State<AppState>,
    Path(customer_id): Path<i32>,
) -> ApiResult<Json<Vec<WishlistItem>>> {
    let rows = sqlx::query_as::<_, WishlistItem>(
        "SELECT p.product_id, p.product_name, CAST(p.price AS DOUBLE) AS price, \
         p.stock_quantity, c.category_name, p.image_url, CAST(w.added_date AS CHAR) AS added_date \
         FROM Wishlist w JOIN Product p ON p.product_id = w.product_id \
         LEFT JOIN Category c ON c.category_id = p.category_id \
         WHERE w.customer_id = ? ORDER BY w.added_date DESC, p.product_name",
    )
    .bind(customer_id)
    .fetch_all(&state.pool)
    .await?;
    Ok(Json(rows))
}

async fn add_wishlist_item(
    State(state): State<AppState>,
    Path(customer_id): Path<i32>,
    Json(body): Json<AddWishlistItem>,
) -> ApiResult<(StatusCode, Json<ApiMessage>)> {
    sqlx::query(
        "INSERT INTO Wishlist (customer_id, product_id, added_date) VALUES (?, ?, CURRENT_DATE)",
    )
    .bind(customer_id)
    .bind(body.product_id)
    .execute(&state.pool)
    .await?;
    Ok((
        StatusCode::CREATED,
        Json(ApiMessage {
            message: "Product added to wishlist".to_string(),
        }),
    ))
}

async fn remove_wishlist_item(
    State(state): State<AppState>,
    Path((customer_id, product_id)): Path<(i32, i32)>,
) -> ApiResult<StatusCode> {
    let result = sqlx::query("DELETE FROM Wishlist WHERE customer_id = ? AND product_id = ?")
        .bind(customer_id)
        .bind(product_id)
        .execute(&state.pool)
        .await?;
    if result.rows_affected() == 0 {
        return Err(ApiError::not_found("Wishlist item not found"));
    }
    Ok(StatusCode::NO_CONTENT)
}

async fn create_order(
    State(state): State<AppState>,
    Json(body): Json<CreateOrder>,
) -> ApiResult<(StatusCode, Json<OrderDetail>)> {
    if body.items.is_empty() {
        return Err(ApiError::bad_request(
            "An order must contain at least one item",
        ));
    }
    require_text(&body.delivery_address, "delivery_address")?;
    if body
        .items
        .iter()
        .any(|item| item.quantity <= 0 || item.product_id <= 0)
    {
        return Err(ApiError::bad_request(
            "Product IDs and quantities must be positive",
        ));
    }
    let mut seen = HashSet::new();
    if body.items.iter().any(|item| !seen.insert(item.product_id)) {
        return Err(ApiError::bad_request(
            "Include each product once and set its quantity",
        ));
    }

    let mut tx = state.pool.begin().await?;
    let mut total_cents: i64 = 0;
    let mut prices = Vec::with_capacity(body.items.len());

    for item in &body.items {
        let stock_row = sqlx::query(
            "SELECT CAST(ROUND(price * 100) AS SIGNED) AS price_cents, stock_quantity \
             FROM Product WHERE product_id = ? FOR UPDATE",
        )
        .bind(item.product_id)
        .fetch_optional(&mut *tx)
        .await?
        .ok_or_else(|| ApiError::not_found(format!("Product {} not found", item.product_id)))?;
        let price_cents: i64 = stock_row.try_get("price_cents")?;
        let stock: Option<i32> = stock_row.try_get("stock_quantity")?;
        let stock = stock.ok_or_else(|| ApiError::conflict("Product stock is not configured"))?;
        if i64::from(stock) < i64::from(item.quantity) {
            return Err(ApiError::conflict(format!(
                "Insufficient stock for product {}",
                item.product_id
            )));
        }
        let line_cents = price_cents
            .checked_mul(i64::from(item.quantity))
            .ok_or_else(|| ApiError::bad_request("Order total is too large"))?;
        total_cents = total_cents
            .checked_add(line_cents)
            .ok_or_else(|| ApiError::bad_request("Order total is too large"))?;
        prices.push(price_cents);
        sqlx::query("UPDATE Product SET stock_quantity = stock_quantity - ? WHERE product_id = ?")
            .bind(item.quantity)
            .bind(item.product_id)
            .execute(&mut *tx)
            .await?;
    }

    if total_cents <= 0 {
        return Err(ApiError::bad_request(
            "Order total must be greater than zero",
        ));
    }
    let total = cents_as_decimal(total_cents);
    let order_result = sqlx::query(
        "INSERT INTO Orders (order_date, customer_id, order_status, total_amount) \
         VALUES (CURRENT_DATE, ?, 'Processing', CAST(? AS DECIMAL(10,2)))",
    )
    .bind(body.customer_id)
    .bind(&total)
    .execute(&mut *tx)
    .await?;
    let order_id = checked_id(order_result.last_insert_id())?;

    for (item, price_cents) in body.items.iter().zip(prices) {
        sqlx::query(
            "INSERT INTO Order_Item (order_id, product_id, quantity, unit_price) \
             VALUES (?, ?, ?, CAST(? AS DECIMAL(10,2)))",
        )
        .bind(order_id)
        .bind(item.product_id)
        .bind(item.quantity)
        .bind(cents_as_decimal(price_cents))
        .execute(&mut *tx)
        .await?;
    }

    sqlx::query(
        "INSERT INTO Payment (order_id, payment_date_time, amount, payment_method, payment_status) \
         VALUES (?, NOW(), CAST(? AS DECIMAL(10,2)), ?, 'Pending')",
    )
    .bind(order_id)
    .bind(&total)
    .bind(body.payment_method.as_deref().unwrap_or("Unspecified"))
    .execute(&mut *tx)
    .await?;

    sqlx::query(
        "INSERT INTO Delivery (order_id, scheduled_delivery_date, scheduled_delivery_time, \
         delivery_date, delivery_address, delivery_status) VALUES (?, CAST(? AS DATE), \
         CAST(? AS TIME), NULL, ?, 'Processing')",
    )
    .bind(order_id)
    .bind(body.scheduled_delivery_date.as_deref())
    .bind(body.scheduled_delivery_time.as_deref())
    .bind(body.delivery_address.trim())
    .execute(&mut *tx)
    .await?;

    tx.commit().await?;
    let detail = order_detail(&state.pool, order_id).await?;
    Ok((StatusCode::CREATED, Json(detail)))
}

async fn get_order(
    State(state): State<AppState>,
    Path(order_id): Path<i32>,
) -> ApiResult<Json<OrderDetail>> {
    Ok(Json(order_detail(&state.pool, order_id).await?))
}

async fn list_customer_orders(
    State(state): State<AppState>,
    Path(customer_id): Path<i32>,
) -> ApiResult<Json<Vec<OrderSummary>>> {
    let rows = sqlx::query_as::<_, OrderSummary>(
        "SELECT o.order_id, o.customer_id, CAST(o.order_date AS CHAR) AS order_date, \
         o.order_status, CAST(o.total_amount AS DOUBLE) AS total_amount, p.payment_status \
         FROM Orders o LEFT JOIN Payment p ON p.order_id = o.order_id \
         WHERE o.customer_id = ? ORDER BY o.order_date DESC, o.order_id DESC",
    )
    .bind(customer_id)
    .fetch_all(&state.pool)
    .await?;
    Ok(Json(rows))
}

async fn update_payment_status(
    State(state): State<AppState>,
    Path(order_id): Path<i32>,
    Json(body): Json<StatusUpdate>,
) -> ApiResult<Json<ApiMessage>> {
    let status = canonical_status(&body.status, &["Pending", "Paid", "Failed", "Refunded"])?;
    let result = sqlx::query("UPDATE Payment SET payment_status = ? WHERE order_id = ?")
        .bind(status)
        .bind(order_id)
        .execute(&state.pool)
        .await?;
    if result.rows_affected() == 0 {
        return Err(ApiError::not_found(
            "Payment record not found for this order",
        ));
    }
    Ok(Json(ApiMessage {
        message: "Payment status updated".to_string(),
    }))
}

async fn update_delivery_status(
    State(state): State<AppState>,
    Path(order_id): Path<i32>,
    Json(body): Json<StatusUpdate>,
) -> ApiResult<Json<ApiMessage>> {
    let status = canonical_status(&body.status, &["Processing", "In Transit", "Delivered"])?;
    let mut tx = state.pool.begin().await?;
    let result = sqlx::query(
        "UPDATE Delivery SET delivery_status = ?, delivery_date = \
         CASE WHEN ? = 'Delivered' THEN CURRENT_DATE ELSE delivery_date END WHERE order_id = ?",
    )
    .bind(status)
    .bind(status)
    .bind(order_id)
    .execute(&mut *tx)
    .await?;
    if result.rows_affected() == 0 {
        return Err(ApiError::not_found(
            "Delivery record not found for this order",
        ));
    }
    if status == "Delivered" || status == "In Transit" || status == "Processing" {
        let order_status = match status {
            "Delivered" => "Delivered",
            "In Transit" => "Shipped",
            _ => "Processing",
        };
        sqlx::query("UPDATE Orders SET order_status = ? WHERE order_id = ?")
            .bind(order_status)
            .bind(order_id)
            .execute(&mut *tx)
            .await?;
    }
    tx.commit().await?;
    Ok(Json(ApiMessage {
        message: "Delivery status updated".to_string(),
    }))
}

#[derive(serde::Serialize, sqlx::FromRow)]
struct ReportSummary {
    total_customers: i64,
    total_products: i64,
    average_product_price: Option<f64>,
    total_orders: i64,
    total_revenue: Option<f64>,
    total_products_sold: Option<i64>,
}

async fn report_summary(State(state): State<AppState>) -> ApiResult<Json<ReportSummary>> {
    let summary = sqlx::query_as::<_, ReportSummary>(
        "SELECT (SELECT COUNT(*) FROM Customer) AS total_customers, \
         (SELECT COUNT(*) FROM Product) AS total_products, \
         (SELECT CAST(AVG(price) AS DOUBLE) FROM Product) AS average_product_price, \
         (SELECT COUNT(*) FROM Orders) AS total_orders, \
         (SELECT CAST(SUM(total_amount) AS DOUBLE) FROM Orders) AS total_revenue, \
         (SELECT CAST(SUM(quantity) AS SIGNED) FROM Order_Item) AS total_products_sold",
    )
    .fetch_one(&state.pool)
    .await?;
    Ok(Json(summary))
}

async fn product_by_id(pool: &MySqlPool, id: i32) -> ApiResult<Product> {
    sqlx::query_as::<_, Product>(
        "SELECT p.product_id, p.product_name, CAST(p.price AS DOUBLE) AS price, \
         p.stock_quantity, p.category_id, c.category_name, p.image_url FROM Product p \
         LEFT JOIN Category c ON c.category_id = p.category_id WHERE p.product_id = ?",
    )
    .bind(id)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| ApiError::not_found("Product not found"))
}

async fn category_by_id(pool: &MySqlPool, id: i32) -> ApiResult<Category> {
    sqlx::query_as::<_, Category>(
        "SELECT category_id, category_name, description FROM Category WHERE category_id = ?",
    )
    .bind(id)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| ApiError::not_found("Category not found"))
}

async fn customer_by_id(pool: &MySqlPool, id: i32) -> ApiResult<Customer> {
    sqlx::query_as::<_, Customer>(
        "SELECT customer_id, name, email, phone, address FROM Customer WHERE customer_id = ?",
    )
    .bind(id)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| ApiError::not_found("Customer not found"))
}

async fn order_detail(pool: &MySqlPool, id: i32) -> ApiResult<OrderDetail> {
    let order = sqlx::query_as::<_, OrderSummary>(
        "SELECT o.order_id, o.customer_id, CAST(o.order_date AS CHAR) AS order_date, \
         o.order_status, CAST(o.total_amount AS DOUBLE) AS total_amount, p.payment_status \
         FROM Orders o LEFT JOIN Payment p ON p.order_id = o.order_id WHERE o.order_id = ?",
    )
    .bind(id)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| ApiError::not_found("Order not found"))?;
    let items = sqlx::query_as::<_, OrderLine>(
        "SELECT oi.product_id, p.product_name, oi.quantity, \
         CAST(oi.unit_price AS DOUBLE) AS unit_price FROM Order_Item oi \
         JOIN Product p ON p.product_id = oi.product_id WHERE oi.order_id = ?",
    )
    .bind(id)
    .fetch_all(pool)
    .await?;
    let payment = sqlx::query_as::<_, PaymentInfo>(
        "SELECT payment_id, CAST(amount AS DOUBLE) AS amount, payment_method, payment_status, \
         CAST(payment_date_time AS CHAR) AS payment_date_time FROM Payment WHERE order_id = ?",
    )
    .bind(id)
    .fetch_optional(pool)
    .await?;
    let delivery = sqlx::query_as::<_, DeliveryInfo>(
        "SELECT delivery_id, CAST(scheduled_delivery_date AS CHAR) AS scheduled_delivery_date, \
         CAST(scheduled_delivery_time AS CHAR) AS scheduled_delivery_time, \
         CAST(delivery_date AS CHAR) AS delivery_date, delivery_address, delivery_status \
         FROM Delivery WHERE order_id = ?",
    )
    .bind(id)
    .fetch_optional(pool)
    .await?;
    Ok(OrderDetail {
        order,
        items,
        payment,
        delivery,
    })
}

fn require_text(value: &str, field: &str) -> ApiResult<()> {
    if value.trim().is_empty() {
        return Err(ApiError::bad_request(format!("{field} cannot be empty")));
    }
    Ok(())
}

fn validate_product(body: &ProductInput) -> ApiResult<()> {
    require_text(&body.product_name, "product_name")?;
    if !body.price.is_finite() || body.price <= 0.0 {
        return Err(ApiError::bad_request("price must be greater than zero"));
    }
    if body.stock_quantity < 0 {
        return Err(ApiError::bad_request("stock_quantity cannot be negative"));
    }
    if body.image_url.as_deref().is_some_and(|url| {
        url.len() > 512 || !(url.starts_with("https://") || url.starts_with("http://"))
    }) {
        return Err(ApiError::bad_request(
            "image_url must be an HTTP or HTTPS URL of at most 512 characters",
        ));
    }
    Ok(())
}

fn validate_customer(body: &CustomerInput) -> ApiResult<()> {
    require_text(&body.name, "name")?;
    require_text(&body.address, "address")?;
    Ok(())
}

fn canonical_status<'a>(provided: &str, allowed: &'a [&'a str]) -> ApiResult<&'a str> {
    allowed
        .iter()
        .copied()
        .find(|status| status.eq_ignore_ascii_case(provided.trim()))
        .ok_or_else(|| {
            ApiError::bad_request(format!("status must be one of: {}", allowed.join(", ")))
        })
}

fn cents_as_decimal(cents: i64) -> String {
    format!("{}.{:02}", cents / 100, cents % 100)
}

fn checked_id(id: u64) -> ApiResult<i32> {
    i32::try_from(id)
        .map_err(|_| ApiError::conflict("Generated ID exceeds the database column range"))
}
