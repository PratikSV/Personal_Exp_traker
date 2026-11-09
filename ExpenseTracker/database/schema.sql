-- =====================================================================
-- Personal Expense Tracker Database Schema
-- Member 1: Database & Core Utilities Module
-- Database: expense_tracker_db
-- Target: MySQL 8.x
-- =====================================================================

CREATE DATABASE IF NOT EXISTS expense_tracker_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE expense_tracker_db;

-- ---------------------------------------------------------------------
-- Table: users
-- Stores registered user accounts with salted & hashed passwords
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Table: expenses
-- Stores user expenses linked to a specific user
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS expenses (
    expense_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(100) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    category VARCHAR(50) NOT NULL,
    expense_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_expenses_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Indexes
-- Composite index for fast filtering & ordering by user and date
-- ---------------------------------------------------------------------
CREATE INDEX idx_user_expense_date ON expenses (user_id, expense_date);

