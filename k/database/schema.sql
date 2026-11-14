CREATE DATABASE IF NOT EXISTS personal_expense_tracker CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE personal_expense_tracker;
CREATE TABLE IF NOT EXISTS users (
 user_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, full_name VARCHAR(120) NOT NULL,
 email VARCHAR(190) NOT NULL, password_hash VARCHAR(255) NOT NULL,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 PRIMARY KEY(user_id), UNIQUE KEY uk_users_email(email)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS categories (
 category_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,user_id BIGINT UNSIGNED NOT NULL,
 category_name VARCHAR(80) NOT NULL,category_type ENUM('EXPENSE','INCOME','BOTH') NOT NULL DEFAULT 'EXPENSE',
 is_default TINYINT(1) NOT NULL DEFAULT 0,created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY(category_id),CONSTRAINT fk_categories_user FOREIGN KEY(user_id) REFERENCES users(user_id) ON DELETE CASCADE,
 UNIQUE KEY uk_categories_user_name_type(user_id,category_name,category_type),KEY idx_categories_user(user_id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS expenses (
 expense_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,user_id BIGINT UNSIGNED NOT NULL,category_id BIGINT UNSIGNED NULL,
 title VARCHAR(150) NOT NULL,amount DECIMAL(12,2) NOT NULL,description TEXT NULL,expense_date DATE NOT NULL,notes TEXT NULL,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 PRIMARY KEY(expense_id),CONSTRAINT fk_expenses_user FOREIGN KEY(user_id) REFERENCES users(user_id) ON DELETE CASCADE,
 CONSTRAINT fk_expenses_category FOREIGN KEY(category_id) REFERENCES categories(category_id) ON DELETE SET NULL,
 CONSTRAINT chk_expenses_amount CHECK(amount>0),KEY idx_expenses_user_date(user_id,expense_date),KEY idx_expenses_user_category(user_id,category_id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS income (
 income_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,user_id BIGINT UNSIGNED NOT NULL,category_id BIGINT UNSIGNED NULL,
 title VARCHAR(150) NOT NULL,source VARCHAR(120) NULL,amount DECIMAL(12,2) NOT NULL,description TEXT NULL,income_date DATE NOT NULL,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 PRIMARY KEY(income_id),CONSTRAINT fk_income_user FOREIGN KEY(user_id) REFERENCES users(user_id) ON DELETE CASCADE,
 CONSTRAINT fk_income_category FOREIGN KEY(category_id) REFERENCES categories(category_id) ON DELETE SET NULL,
 CONSTRAINT chk_income_amount CHECK(amount>0),KEY idx_income_user_date(user_id,income_date),KEY idx_income_user_category(user_id,category_id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS budgets (
 budget_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,user_id BIGINT UNSIGNED NOT NULL,category_id BIGINT UNSIGNED NULL,
 budget_name VARCHAR(120) NOT NULL,amount DECIMAL(12,2) NOT NULL,budget_month DATE NOT NULL COMMENT 'First day of budget month',
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 PRIMARY KEY(budget_id),CONSTRAINT fk_budgets_user FOREIGN KEY(user_id) REFERENCES users(user_id) ON DELETE CASCADE,
 CONSTRAINT fk_budgets_category FOREIGN KEY(category_id) REFERENCES categories(category_id) ON DELETE CASCADE,
 CONSTRAINT chk_budgets_amount CHECK(amount>0),UNIQUE KEY uk_budgets_user_category_month(user_id,category_id,budget_month),KEY idx_budgets_user_month(user_id,budget_month)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS remember_tokens (
 token_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,user_id BIGINT UNSIGNED NOT NULL,selector CHAR(36) NOT NULL,
 token_hash CHAR(64) NOT NULL,expires_at DATETIME NOT NULL,created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,last_used_at DATETIME NULL,
 PRIMARY KEY(token_id),CONSTRAINT fk_remember_tokens_user FOREIGN KEY(user_id) REFERENCES users(user_id) ON DELETE CASCADE,
 UNIQUE KEY uk_remember_selector(selector),KEY idx_remember_user(user_id),KEY idx_remember_expiry(expires_at)
) ENGINE=InnoDB;
