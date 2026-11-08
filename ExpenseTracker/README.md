# Personal Expense Tracker

A multi-user web application built with **Java Servlet, JSP, JSTL, and MySQL** following the MVC architectural pattern. It allows users to register, securely log in, and track their expenses with category summaries, sorting capabilities, and data isolation between users.

---

## Academic Team Module Distribution

| Module | Team Member | Deliverables / Files |
| :--- | :--- | :--- |
| **Member 1** | Database & Core Utilities | `database/schema.sql`, `util/DBConnection.java`, `util/PasswordUtil.java` |
| **Member 2** | Models & User Access | `model/User.java`, `model/Expense.java`, `dao/UserDAO.java` |
| **Member 3** | Expense Data Access | `dao/ExpenseDAO.java` |
| **Member 4** | Authentication & Security | `filter/AuthFilter.java`, `servlet/AuthServlet.java` |
| **Member 5** | Expense Management & UI | `servlet/ExpenseServlet.java`, `WEB-INF/web.xml`, `index.jsp`, `login.jsp`, `register.jsp`, `css/style.css`, `js/validation.js` |

---

## Technology Stack & Environment

- **Server:** Apache Tomcat 10+ / 11 (uses standard `jakarta.servlet.*` namespace)
- **Java Platform:** Java SE 17+ (Project configured for Java 25)
- **Database:** MySQL 8.x
- **JDBC Driver:** MySQL Connector/J 8.4.0 (`com.mysql.cj.jdbc.Driver`)
- **Template / View:** JSP 3.0 / Jakarta JSTL 3.0
- **Libraries in `WEB-INF/lib`:**
  - `mysql-connector-j-8.4.0.jar`
  - `jakarta.servlet.jsp.jstl-api-3.0.0.jar`
  - `jakarta.servlet.jsp.jstl-3.0.1.jar`

---

## Setup & Execution Instructions

### Step 1: Run the Database Schema
1. Open your MySQL client (MySQL Workbench, MySQL Command Line, or phpMyAdmin).
2. Execute the script located at:
   ```
   ExpenseTracker/database/schema.sql
   ```
   This creates the database `expense_tracker_db` and tables `users`, `expenses`, with foreign keys and composite indexes (`idx_user_expense_date`).

### Step 2: Configure MySQL Password
1. Open `ExpenseTracker/src/main/java/util/DBConnection.java`.
2. Locate the line with the `TODO`:
   ```java
   // TODO: Enter your MySQL password here before running the application!
   private static final String DB_PASSWORD = "root";
   ```
3. Replace `"root"` with your actual MySQL password.
4. *(Optional verification)*: Run `DBConnection.java` directly as a Java Application in Eclipse (`Run As > Java Application`) to verify that the connection succeeds.

### Step 3: Refresh the Project in Eclipse
1. In Eclipse, right-click the `ExpenseTracker` project in **Project Explorer** and press **F5** (or click **Refresh**).
2. Go to **Project > Properties > Java Build Path > Libraries**.
3. Ensure the JARs in `Web App Libraries` (`WEB-INF/lib/`) are visible and that Apache Tomcat runtime is targeted under **Targeted Runtimes**.

### Step 4: Run on Apache Tomcat
1. In the **Servers** tab in Eclipse, right-click and choose **Add and Remove...**.
2. Add `ExpenseTracker` to the configured Tomcat server (e.g. Tomcat 10.1 or 11).
3. Start the Tomcat server.
4. Open your browser and navigate to:
   ```
   http://localhost:8080/ExpenseTracker/
   ```
   *(Or click "Run As > Run on Server" on the project in Eclipse).*

---

## Security Architecture & Checklist Verification

- [x] **No SQL Injection:** 100% parameterization with `PreparedStatement`. Whitelisted sorting column parameters.
- [x] **Cryptographic Password Storage:** `PBKDF2WithHmacSHA256` with random 16-byte salt, 65,536 iterations, formatted as `iterations:saltBase64:hashBase64`.
- [x] **Constant-time Equality Check:** `MessageDigest.isEqual` to neutralize timing side-channel attacks.
- [x] **Session Fixation Defense:** `request.changeSessionId()` called immediately upon successful user login.
- [x] **No User Enumeration:** Generic `"Invalid email or password."` message returned upon login errors.
- [x] **Complete Multi-Tenant Isolation:** `user_id` is extracted strictly from the validated `HttpSession`, never from client parameters.
- [x] **IDOR Protection on Deletion:** `DELETE FROM expenses WHERE id = ? AND user_id = ?` ensures a user cannot delete another user's expenses.
- [x] **Cross-Site Scripting (XSS) Prevention:** Output rendering uses `<c:out>` and JSTL formatters across all views.
- [x] **Browser Back-Button Protection:** `AuthFilter` applies HTTP no-cache headers (`Cache-Control: no-cache, no-store, must-revalidate`, `Pragma: no-cache`, `Expires: 0`).
- [x] **Post-Redirect-Get (PRG):** Form submissions redirect to `/expenses` or `/login.jsp` to avoid form resubmission dialogs on refresh.

---

## Manual Test Checklist

| # | Test Scenario | Steps to Execute | Expected Result |
| :---: | :--- | :--- | :--- |
| **1** | **User Registration** | 1. Go to `/register.jsp`.<br>2. Fill in username `alice`, email `alice@example.com`, password `secret123`, confirm `secret123`.<br>3. Click "Create Account". | Redirects to `login.jsp` with green success alert banner: *"Registration successful! Please log in."* |
| **2** | **Duplicate Username Rejection** | 1. Go to `/register.jsp`.<br>2. Attempt to register again with username `alice` and a different email `alice2@example.com`. | Displays red alert: *"Username is already taken. Please choose another."* |
| **3** | **Duplicate Email Rejection** | 1. Go to `/register.jsp`.<br>2. Attempt to register with username `bob` and email `alice@example.com`. | Displays red alert: *"An account with this email already exists."* |
| **4** | **Invalid Login Attempt** | 1. Go to `/login.jsp`.<br>2. Enter email `alice@example.com` with wrong password `wrongpass`. | Displays generic red alert: *"Invalid email or password."* (No username/email disclosure). |
| **5** | **Successful Login** | 1. Enter email `alice@example.com` and password `secret123`.<br>2. Click "Sign In". | Redirects to `/expenses` (dashboard). Displays *"Welcome, alice"* in navbar. |
| **6** | **Add Valid Expense** | 1. In Add Expense card, enter Title: `Groceries`, Amount: `54.50`, Category: `Food`, Date: today's date.<br>2. Click "+ Add Expense". | Page reloads showing success message. Expense table displays item with red `Food` badge. Total Spending updates to `$54.50`. |
| **7** | **Add Invalid Expense (Client & Server Validation)** | 1. Enter empty title or negative amount `-10.00`.<br>2. Try to submit. | Submission blocked by client JS validation. Server also validates and rejects invalid payloads. |
| **8** | **Sorting Expenses** | 1. Add multiple expenses with different amounts and categories.<br>2. Click "Amount", "Category", or "Date" sort pills. | Table updates ordering dynamically without data loss. |
| **9** | **Delete Expense with Confirmation** | 1. Click "Delete" on an expense.<br>2. A confirmation prompt pops up: *"Are you sure you want to delete..."*.<br>3. Click "OK". | Item is deleted. Total Spending and Category Breakdown decrement accordingly. |
| **10** | **Logout & Session Invalidation** | 1. Click "Logout" button in navbar. | Redirects to `login.jsp` with logout message. Session is invalidated. |
| **11** | **Unauthenticated Access Protection** | 1. After logout, attempt to access `http://localhost:8080/ExpenseTracker/index.jsp` or `/expenses`. | `AuthFilter` intercepts request and immediately redirects to `login.jsp`. |
| **12** | **Browser Back-Button Test** | 1. After logout, press the browser Back button. | Browser does not show cached sensitive expense data due to no-cache response headers. |
| **13** | **IDOR / URL Tampering Defense** | 1. Register and log in as `bob`.<br>2. Inspect HTML or construct POST to `/expenses` with `action=delete&id=<alice_expense_id>`. | Deletion fails. Bob cannot delete Alice's expense because the DAO strictly checks `WHERE id = ? AND user_id = ?`. |

---

## Assumptions Made

1. **Tomcat & Servlet Specification:** Tomcat 10+ / 11 was detected in the environment (`C:\apache-tomcat-11.0.4`), and project facet indicates `jst.web 5.0` and `java 25`. Therefore, the standard `jakarta.servlet.*` package namespace was used along with Jakarta JSTL 3.0.
2. **Database Port & Credentials:** Default MySQL configuration is assumed at `localhost:3306`, user `root`, password `root` (with explicit TODO comment for the user to edit their actual password in `DBConnection.java`).
3. **Session Management:** Standard 30-minute HTTP cookie sessions with `HttpOnly` flags and server-side invalidation.

