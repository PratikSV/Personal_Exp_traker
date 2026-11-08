package util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBConnection {

    // JDBC Driver and Database URL
    private static final String DRIVER_CLASS = "com.mysql.cj.jdbc.Driver";
    private static final String DB_URL = "jdbc:mysql://localhost:3306/expense_tracker_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";

    // Database credentials
    private static final String DB_USER = "root";

    // MySQL password configured
    private static final String DB_PASSWORD = "gnims";

    static {
        try {
            Class.forName(DRIVER_CLASS);
        } catch (ClassNotFoundException e) {
            throw new RuntimeException(
                    "MySQL JDBC Driver not found in classpath. Ensure mysql-connector-j JAR is in WEB-INF/lib.", e);
        }
    }

    /**
     * Private constructor to prevent instantiation of utility class.
     */
    private DBConnection() {
    }

    /**
     * Obtains a new connection to the MySQL database.
     * Callers must close the connection, preferably using try-with-resources.
     *
     * @return a valid java.sql.Connection
     * @throws SQLException if a database access error occurs
     */
    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
    }

    /**
     * Test execution harness for Member 1 deliverable.
     * Verifies driver loading and tests live database connectivity.
     */
    public static void main(String[] args) {
        System.out.println("=================================================");
        System.out.println("ExpenseTracker: Testing MySQL Database Connection");
        System.out.println("URL: " + DB_URL);
        System.out.println("User: " + DB_USER);
        System.out.println("=================================================");

        try (Connection conn = DBConnection.getConnection()) {
            if (conn != null && !conn.isClosed()) {
                System.out.println("SUCCESS: Successfully connected to database: " + conn.getCatalog());
            } else {
                System.err.println("FAILURE: Connection is null or closed.");
            }
        } catch (SQLException e) {
            System.err.println("CONNECTION ERROR: Failed to connect to MySQL database.");
            System.err.println("Message: " + e.getMessage());
            System.err.println("Tip: Ensure MySQL server is running, the database 'expense_tracker_db' exists,");
            System.err.println("and DB_PASSWORD in DBConnection.java is set to your MySQL root password.");
        }
    }
}
