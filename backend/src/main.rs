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

    // A failed first deployment can leave SQLx's version-1 migration marked
    // dirty. Recover only the known pristine-database case: no application
    // tables exist and the sole migration record is the failed version 1.
    // Any partially initialized or populated database is left untouched.
    let application_tables: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM information_schema.tables \
         WHERE table_schema = DATABASE() \
         AND table_name IN ('Customer', 'Category', 'Product', 'Orders', \
                            'Order_Item', 'Payment', 'Delivery', 'Wishlist')",
    )
    .fetch_one(&pool)
    .await?;
    if application_tables == 0 {
        let migration_table_exists: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM information_schema.tables \
             WHERE table_schema = DATABASE() AND table_name = '_sqlx_migrations'",
        )
        .fetch_one(&pool)
        .await?;
        if migration_table_exists == 1 {
            let migration_records: i64 =
                sqlx::query_scalar("SELECT COUNT(*) FROM _sqlx_migrations")
                    .fetch_one(&pool)
                    .await?;
            let failed_first_migration: i64 = sqlx::query_scalar(
                "SELECT COUNT(*) FROM _sqlx_migrations \
                 WHERE version = 1 AND success = 0",
            )
            .fetch_one(&pool)
            .await?;
            if migration_records == 1 && failed_first_migration == 1 {
                sqlx::query("DELETE FROM _sqlx_migrations WHERE version = 1 AND success = 0")
                    .execute(&pool)
                    .await?;
                eprintln!("Cleared the failed initial migration marker for an empty database");
            }
        }
    }

    // The migrations create the demo schema, configure generated IDs, and seed
    // the catalog when the target database is empty.
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
