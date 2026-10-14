use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct Category {
    pub category_id: i32,
    pub category_name: String,
    pub description: Option<String>,
}

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct Product {
    pub product_id: i32,
    pub product_name: String,
    pub price: f64,
    pub stock_quantity: Option<i32>,
    pub category_id: Option<i32>,
    pub category_name: Option<String>,
    pub image_url: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct ProductInput {
    pub product_name: String,
    pub price: f64,
    pub stock_quantity: i32,
    pub category_id: Option<i32>,
    pub image_url: Option<String>,
}

#[derive(Debug, Deserialize, Default)]
pub struct ProductFilter {
    pub category_id: Option<i32>,
    pub search: Option<String>,
}

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct Customer {
    pub customer_id: i32,
    pub name: String,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub address: String,
}

#[derive(Debug, Deserialize)]
pub struct CustomerInput {
    pub name: String,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub address: String,
}

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct WishlistItem {
    pub product_id: i32,
    pub product_name: String,
    pub price: f64,
    pub stock_quantity: Option<i32>,
    pub category_name: Option<String>,
    pub image_url: Option<String>,
    pub added_date: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct AddWishlistItem {
    pub product_id: i32,
}

#[derive(Debug, Deserialize)]
pub struct CreateOrder {
    pub customer_id: i32,
    pub items: Vec<OrderItemInput>,
    pub payment_method: Option<String>,
    pub delivery_address: String,
    pub scheduled_delivery_date: Option<String>,
    pub scheduled_delivery_time: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct OrderItemInput {
    pub product_id: i32,
    pub quantity: i32,
}

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct OrderSummary {
    pub order_id: i32,
    pub customer_id: i32,
    pub order_date: Option<String>,
    pub order_status: Option<String>,
    pub total_amount: f64,
    pub payment_status: Option<String>,
}

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct OrderLine {
    pub product_id: i32,
    pub product_name: String,
    pub quantity: i32,
    pub unit_price: f64,
}

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct PaymentInfo {
    pub payment_id: i32,
    pub amount: f64,
    pub payment_method: Option<String>,
    pub payment_status: Option<String>,
    pub payment_date_time: Option<String>,
}

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct DeliveryInfo {
    pub delivery_id: i32,
    pub scheduled_delivery_date: Option<String>,
    pub scheduled_delivery_time: Option<String>,
    pub delivery_date: Option<String>,
    pub delivery_address: String,
    pub delivery_status: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct OrderDetail {
    pub order: OrderSummary,
    pub items: Vec<OrderLine>,
    pub payment: Option<PaymentInfo>,
    pub delivery: Option<DeliveryInfo>,
}

#[derive(Debug, Deserialize)]
pub struct StatusUpdate {
    pub status: String,
}

#[derive(Debug, Serialize)]
pub struct ApiMessage {
    pub message: String,
}
