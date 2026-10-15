mod api;
mod error;
mod models;

use axum::http::HeaderValue;
use sqlx::mysql::MySqlPoolOptions;
use std::net::SocketAddr;
use tower_http::cors::{AllowOrigin, Any, CorsLayer};

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

    let cors_origins = std::env::var("CORS_ORIGINS").unwrap_or_else(|_| {
        "http://localhost:3001,http://127.0.0.1:3001".to_string()
    });
    let allowed_origins = cors_origins
        .split(',')
        .map(str::trim)
        .filter(|origin| !origin.is_empty())
        .map(HeaderValue::from_str)
        .collect::<Result<Vec<_>, _>>()?;
    let app = api::router(api::AppState { pool }).layer(
        CorsLayer::new()
            .allow_origin(AllowOrigin::list(allowed_origins))
            .allow_methods(Any)
            .allow_headers(Any),
    );

    let port = std::env::var("PORT")
        .unwrap_or_else(|_| "3000".to_string())
        .parse::<u16>()?;
    let default_host = if std::env::var_os("PORT").is_some() {
        "0.0.0.0"
    } else {
        "127.0.0.1"
    };
    let host = std::env::var("HOST").unwrap_or_else(|_| default_host.to_string());
    let address: SocketAddr = format!("{host}:{port}").parse()?;
    let listener = tokio::net::TcpListener::bind(address).await?;

    println!("E-Commerce API listening at http://{address}");
    println!("Health check: http://{address}/health");
    axum::serve(listener, app).await?;
    Ok(())
}
