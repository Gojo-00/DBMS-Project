CREATE TABLE IF NOT EXISTS OtpChallenge (
    challenge_id CHAR(36) NOT NULL PRIMARY KEY,
    contact VARCHAR(254) NOT NULL,
    channel ENUM('email', 'phone') NOT NULL,
    purpose ENUM('signup', 'signin') NOT NULL,
    customer_name VARCHAR(120) NULL,
    code_hash CHAR(64) NOT NULL,
    attempt_count TINYINT UNSIGNED NOT NULL DEFAULT 0,
    expires_at DATETIME NOT NULL,
    used_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_otp_contact_created (contact, created_at),
    INDEX idx_otp_expiry (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
