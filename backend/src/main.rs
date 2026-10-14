mod api;
mod error;
mod models;

use sqlx::mysql::MySqlPoolOptions;
use std::net::SocketAddr;
use tower_http::cors::CorsLayer;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    dotenvy::dotenv().ok();

    let database_url = std::env::var("DATABASE_URL")
        .map_err(|_| "DATABASE_URL is missing; add it to backend/.env")?;
    let pool = MySqlPoolOptions::new()
        .max_connections(10)
        .connect(&database_url)
        .await?;

    // The supplied schema used manual integer IDs. This migration enables MySQL
    // to generate IDs safely for API-created records.
    sqlx::migrate!("./migrations").run(&pool).await?;

    let app = api::router(api::AppState { pool }).layer(CorsLayer::permissive());
    let address: SocketAddr = "127.0.0.1:3000".parse()?;
    let listener = tokio::net::TcpListener::bind(address).await?;

    println!("E-Commerce API listening at http://{address}");
    println!("Health check: http://{address}/health");
    axum::serve(listener, app).await?;
    Ok(())
}
