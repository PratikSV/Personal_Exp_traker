# Pennywise — Personal Expense Tracker

A responsive Java web application built with Java 21, Spring MVC, Spring JDBC, JSP/JSTL, MySQL 8 and Chart.js. It is a traditional Maven WAR application for Apache Tomcat 10.1 (not Spring Boot).

## Features
- Account registration and sign-in with BCrypt password hashing
- Session-based login/logout and CSRF tokens on POST forms
- User-scoped income and expense records with prepared SQL parameters
- Dashboard totals, six-month cash-flow bar chart and category doughnut chart
- Monthly category budgets with progress indicators
- Responsive layouts for mobile, tablet and desktop
- Default categories created for each new account

## Requirements
JDK 21, Maven 3.9+, MySQL 8, Apache Tomcat 10.1.

## First-time database setup
1. Open MySQL Workbench and execute `database/schema.sql`.
2. In PowerShell set the database connection values (replace the password locally):
   `$env:DB_URL="jdbc:mysql://localhost:3306/personal_expense_tracker?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Kolkata"`
   `$env:DB_USERNAME="root"`
   `$env:DB_PASSWORD="YOUR_LOCAL_MYSQL_PASSWORD"`
3. Keep that PowerShell session available when launching Tomcat so it inherits these variables.

## Build and deploy
1. From the folder containing `pom.xml`, run `mvn clean package`.
2. Copy `target\personal-expense-tracker.war` to `<TOMCAT_HOME>\webapps`.
3. Start Tomcat using `<TOMCAT_HOME>\bin\catalina.bat run`.
4. Open `http://localhost:8080/personal-expense-tracker/register`.

## VS Code
Open this folder in VS Code. Use Terminal → Run Task:
- `1 - Build WAR`
- `2 - Deploy WAR to Tomcat` (asks for Tomcat folder)
- `3 - Start Tomcat (current terminal)` (asks for Tomcat folder; run from a terminal with DB variables set)
- `4 - Open application`

## Suggested demo flow
1. Register two accounts to demonstrate per-user data isolation.
2. Sign in and add income (e.g. Salary ₹35,000).
3. Add expenses in different categories.
4. Open Dashboard to show live totals and charts.
5. Create a monthly budget and add a matching expense to demonstrate the progress indicator.
6. Sign out and sign in again.

## Scope / honest limitations
This is a compact deadline-oriented academic project build. It includes the core flows above, but does not yet include edit/update transaction forms, persistent Remember Me, password reset, export to PDF/Excel, advanced filters, or production deployment hardening. Chart.js and Google Fonts are loaded from CDNs, so charts/fonts require internet access in the browser. Test all flows locally before presenting.
