package dao;

import model.User;
import util.DBConnection;
import util.PasswordUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * =====================================================================
 * Member 2 Deliverable: User Data Access Object (DAO)
 * Project: Personal Expense Tracker
 * =====================================================================
 * Handles all database operations for user accounts: registration,
 * existence checks, and credential validation. Uses PreparedStatements exclusively.
 */
public class UserDAO {

    /**
     * Checks if a user already exists with the given username.
     *
     * @param username username to check (case-insensitive search)
     * @return true if username exists, false otherwise
     */
    public boolean existsByUsername(String username) {
        String sql = "SELECT user_id FROM users WHERE LOWER(username) = LOWER(?) LIMIT 1";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) {
            System.err.println("UserDAO.existsByUsername error: " + e.getMessage());
            return false;
        }
    }

    /**
     * Checks if a user already exists with the given email.
     *
     * @param email email to check (case-insensitive search)
     * @return true if email exists, false otherwise
     */
    public boolean existsByEmail(String email) {
        String sql = "SELECT user_id FROM users WHERE LOWER(email) = LOWER(?) LIMIT 1";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) {
            System.err.println("UserDAO.existsByEmail error: " + e.getMessage());
            return false;
        }
    }

    /**
     * Registers a new user into the database.
     *
     * @param user user entity with username, email, and hashed password
     * @return true if registration succeeded, false otherwise
     */
    public boolean registerUser(User user) {
        String sql = "INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, user.getUsername());
            ps.setString(2, user.getEmail());
            ps.setString(3, user.getPasswordHash());

            int affectedRows = ps.executeUpdate();
            if (affectedRows > 0) {
                try (ResultSet generatedKeys = ps.getGeneratedKeys()) {
                    if (generatedKeys.next()) {
                        user.setId(generatedKeys.getInt(1));
                    }
                }
                return true;
            }
            return false;
        } catch (SQLException e) {
            System.err.println("UserDAO.registerUser error: " + e.getMessage());
            return false;
        }
    }

    /**
     * Validates user credentials. Checks the entered email and verifies the
     * candidate password against the stored PBKDF2 hash using constant-time comparison.
     *
     * @param email user email address
     * @param plainPassword plaintext candidate password
     * @return User object (without password hash) if valid, null otherwise
     */
    public User validateLogin(String email, String plainPassword) {
        if (email == null || plainPassword == null || email.trim().isEmpty() || plainPassword.isEmpty()) {
            return null;
        }

        String sql = "SELECT user_id, username, email, password_hash, created_at FROM users WHERE LOWER(email) = LOWER(?) LIMIT 1";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email.trim());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String storedHash = rs.getString("password_hash");
                    if (PasswordUtil.verifyPassword(plainPassword, storedHash)) {
                        User user = new User();
                        user.setId(rs.getInt("user_id"));
                        user.setUsername(rs.getString("username"));
                        user.setEmail(rs.getString("email"));
                        user.setCreatedAt(rs.getTimestamp("created_at"));
                        // Notice: user.passwordHash is deliberately not populated
                        return user;
                    }
                }
            }
        } catch (SQLException e) {
            System.err.println("UserDAO.validateLogin error: " + e.getMessage());
        }
        return null;
    }

    /**
     * Retrieves user details by user ID.
     *
     * @param userId authenticated user ID
     * @return User object (without password hash) if found, null otherwise
     */
    public User getUserById(int userId) {
        String sql = "SELECT user_id, username, email, created_at FROM users WHERE user_id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    User user = new User();
                    user.setId(rs.getInt("user_id"));
                    user.setUsername(rs.getString("username"));
                    user.setEmail(rs.getString("email"));
                    user.setCreatedAt(rs.getTimestamp("created_at"));
                    return user;
                }
            }
        } catch (SQLException e) {
            System.err.println("UserDAO.getUserById error: " + e.getMessage());
        }
        return null;
    }
}

