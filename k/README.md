# Pennywise — Personal Expense Tracker

A modern, responsive Java web application built with **JDK 17**, Spring MVC 6, Spring JDBC, JSP/JSTL (Jakarta EE), MySQL 8, and Chart.js. This is a traditional Maven WAR web application designed for **Apache Tomcat 10.1 / 11.0+** (not Spring Boot). 
tomcat path: C:\apache-tomcat-11.0.4

---

## Features

- **Authentication & Security:**
  - Account registration and login with BCrypt password hashing (`BCryptPasswordEncoder`).
  - Session-based user authentication and CSRF token protection on POST forms.
  - Data isolation ensuring each user accesses only their own records.
  - Auto-generated default expense categories on initial user signup.

- **Financial Analytics & Dashboard:**
  - **Summary Metrics:** Total Balance card and a unified **side-by-side** card displaying Total Income and Total Expenses.
  - **Cash Flow Line Graph:** Visualizes monthly or daily income vs. expense cash flows using Chart.js, paired with a detailed cash flow data breakdown table.
  - **Spending Breakdown Pie Chart:** Interactive pie chart displaying percentage and amount per category, paired with a categorical breakdown list.
  - **Toggleable Filter Report Form:** Filter button positioned right beside "＋ Add transaction" to toggle advanced filtering by:
    - Date range (Start date & End date)
    - Quick presets (Today, Current Month, Last 30 Days, Year-to-Date, All Time)
    - Transaction type (Income, Expense, or All)
    - Specific expense category
  - **Smart Filtering:** Applying filters dynamically updates the cash flow line graph, category pie chart, and transaction list while preserving all-time Total Balance, Income, and Expenses.

- **Transaction & Budget Management:**
  - Add, categorize, and track income and expense entries with prepared SQL parameters.
  - Monthly category budget planner with dynamic spend vs. limit progress indicators.
  - Fully responsive layout for mobile, tablet, and desktop screens.

---

## Architecture Overview

This project follows a clean MVC architecture on top of Jakarta Servlet specifications:

```text
├── src/main/java/com/expensetracker/
│   ├── config/
│   │   ├── DatabaseConfig.java            # DataSource & JdbcTemplate configuration
│   │   ├── WebConfig.java                 # Spring MVC view resolver, resource handlers, & formatters
│   │   └── WebApplicationInitializer.java # Jakarta Servlet 6.0 dispatcher initialization
│   └── controller/
│       └── AppController.java             # Endpoints, queries, session logic & model binding
├── src/main/webapp/
│   ├── WEB-INF/
│   │   ├── views/
│   │   │   ├── dashboard.jsp              # Main financial dashboard, charts, & filters
│   │   │   ├── transactions.jsp           # Income/expense logging and list view
│   │   │   ├── budgets.jsp                # Budget limits and progress indicators
│   │   │   ├── login.jsp                  # User login page
│   │   │   ├── register.jsp               # New user registration
│   │   │   └── nav.jspf                   # Shared navigation header
│   │   └── web.xml                        # Web application deployment descriptor
│   └── static/
│       └── css/
│           └── app.css                    # Responsive stylesheet
├── database/
│   └── schema.sql                         # MySQL 8 table schema definitions
└── pom.xml                                # Maven build and dependency configuration
```

### Technology Stack

| Component | Technology | Version |
|-----------|------------|---------|
| Language / Platform | Java / JDK | 17+ (compiled with `--release 17 -parameters`) |
| Framework | Spring Web MVC, Spring JDBC | 6.2.3 |
| Security | Spring Security Crypto (BCrypt) | 6.4.3 |
| Database | MySQL Server / Connector-J | 8.0+ / 9.2.0 |
| Servlet Specification | Jakarta Servlet API | 6.0.0 (provided) |
| JSP & Taglibs | Jakarta JSP & JSTL API | 3.1.1 / 3.0.2 |
| Application Server | Apache Tomcat | 10.1.x / 11.0.x |
| Frontend | HTML5, CSS3, Chart.js (CDN) | Responsive |

---

## Prerequisites

1. **Java Development Kit (JDK):** JDK 17, 21, or 27 installed.
2. **Apache Maven:** Version 3.9+ installed and added to `PATH`.
3. **MySQL Server:** Version 8.0+ running on `localhost:3306`.
4. **Apache Tomcat:** Tomcat 10.1 or Tomcat 11.0 installed (e.g., `C:\apache-tomcat-11.0.4`).

---

## Database Setup

1. Open MySQL Workbench or your MySQL CLI.
2. Run the SQL script located at `database/schema.sql`:
   ```sql
   SOURCE database/schema.sql;
   ```
   *(Creates database `personal_expense_tracker` and tables: `users`, `categories`, `income`, `expenses`, `budgets`, and `remember_tokens`)*

---

## Server & Environment Configuration

Tomcat reads the database connection parameters via environment variables or `application.properties`.

### Option A: Via Tomcat `bin/setenv.bat` (Recommended)
Create or edit `bin\setenv.bat` inside your Tomcat installation directory (e.g., `C:\apache-tomcat-11.0.4\bin\setenv.bat`):
```cmd
set "JAVA_HOME=C:\Program Files\Java\jdk-27.0.1.0.3"
set "DB_URL=jdbc:mysql://localhost:3306/personal_expense_tracker?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Kolkata"
set "DB_USERNAME=root"
set "DB_PASSWORD=YOUR_MYSQL_PASSWORD"
```

### Option B: Via Terminal Session
If starting Tomcat directly from PowerShell:
```powershell
$env:JAVA_HOME = "C:\Program Files\Java\jdk-27.0.1.0.3"
$env:DB_URL = "jdbc:mysql://localhost:3306/personal_expense_tracker?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Kolkata"
$env:DB_USERNAME = "root"
$env:DB_PASSWORD = "YOUR_MYSQL_PASSWORD"
```

---

## Build and Deployment

### 1. Build the WAR with Maven
In the root directory of the project:
```powershell
mvn clean package -DskipTests
```
This will compile the application and generate `target\personal-expense-tracker.war`.

### 2. Deploy to Apache Tomcat
Copy the WAR file into Tomcat's `webapps` directory:
```powershell
Copy-Item "target\personal-expense-tracker.war" "C:\apache-tomcat-11.0.4\webapps\personal-expense-tracker.war" -Force
```

### 3. Start Apache Tomcat
From the Tomcat `bin` directory:
```powershell
& "C:\apache-tomcat-11.0.4\bin\catalina.bat" run
```

### 4. Access the Application
Open your browser and navigate to:
- **Registration:** [http://localhost:8080/personal-expense-tracker/register](http://localhost:8080/personal-expense-tracker/register)
- **Login:** [http://localhost:8080/personal-expense-tracker/login](http://localhost:8080/personal-expense-tracker/login)
- **Dashboard:** [http://localhost:8080/personal-expense-tracker/dashboard](http://localhost:8080/personal-expense-tracker/dashboard)

---

## Running in VS Code

### Using Community Server Connectors (GUI)
1. Install the extension **Community Server Connectors** (Red Hat) from the VS Code Marketplace.
2. In the **Servers** panel on the left sidebar:
   - Click **`+` (Add Server)** → Select **Apache Tomcat**.
   - Choose your existing installation folder (e.g., `C:\apache-tomcat-11.0.4`).
   - Select your JDK (17 or higher).
3. Right-click the configured server → **Add Deployment...** → Select `target\personal-expense-tracker.war`.
4. Right-click the server and choose **Start Server**.

### Using VS Code Tasks
Press `Ctrl + Shift + P` → select **Tasks: Run Task**:
- `1 - Build WAR`: Compiles and packages the WAR.
- `2 - Deploy WAR to Tomcat`: Copies the WAR to your specified Tomcat path.
- `3 - Start Tomcat (current terminal)`: Launches Tomcat in the terminal.
- `4 - Open application`: Launches the browser to the application URL.

---

## Suggested Demo Flow

1. **Register:** Create a new account at `/register` to test BCrypt hashing and default category creation.
2. **Add Income:** Log salary or freelance income at `/transactions` (e.g., ₹50,000).
3. **Add Expenses:** Log several expenses across categories (e.g., Groceries ₹4,500, Utilities ₹2,200).
4. **Set Monthly Budgets:** Navigate to `/budgets` to assign a spending target and view live progress bars.
5. **Dashboard Analytics:**
   - Review lifetime Total Balance and the side-by-side Total Income & Expenses cards.
   - Inspect the **Cash Flow Line Graph** and data breakdown table.
   - Inspect the **Spending Breakdown Pie Chart** and categorical summary list.
   - Click the **Filter** button next to "Add transaction" to test date range, preset, and category filters.
6. **Sign Out:** Sign out and sign in with a different user to verify complete session and data isolation.

---

## License & Notes
- Developed for academic and personal portfolio demonstration.
- Chart.js and Google Fonts require internet access to load from CDNs.
