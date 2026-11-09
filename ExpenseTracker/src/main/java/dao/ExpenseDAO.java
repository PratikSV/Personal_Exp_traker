package dao;

import model.Expense;
import util.DBConnection;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * =====================================================================
 * Member 3 Deliverable: Expense Data Access Object (DAO)
 * Project: Personal Expense Tracker
 * =====================================================================
 * Handles all database operations for personal expenses.
 * STRICT SECURITY REQUIREMENT:
 * Every SELECT, UPDATE, and DELETE query MUST filter by user_id to enforce
 * complete data isolation across users. PreparedStatements used exclusively.
 */
public class ExpenseDAO {

    /**
     * Inserts a new expense record for the authenticated user.
     *
     * @param expense expense details (must have userId, title, amount, category, expenseDate)
     * @return true if added successfully, false otherwise
     */
    public boolean addExpense(Expense expense) {
        String sql = "INSERT INTO expenses (user_id, title, amount, category, expense_date) VALUES (?, ?, ?, ?, ?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, expense.getUserId());
            ps.setString(2, expense.getTitle());
            ps.setBigDecimal(3, expense.getAmount());
            ps.setString(4, expense.getCategory());
            ps.setDate(5, expense.getExpenseDate());

            int affectedRows = ps.executeUpdate();
            if (affectedRows > 0) {
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) {
                        expense.setId(rs.getInt(1));
                    }
                }
                return true;
            }
            return false;
        } catch (SQLException e) {
            System.err.println("ExpenseDAO.addExpense error: " + e.getMessage());
            return false;
        }
    }

    /**
     * Retrieves all expenses belonging to a specific user, with optional sorting.
     * Enforces user_id filtering. Uses a strict whitelist for the sort clause
     * to prevent SQL injection.
     *
     * @param userId ID of the authenticated user
     * @param sortBy optional sort field: "date", "amount", or "category"
     * @return list of expenses
     */
    public List<Expense> getExpensesByUser(int userId, String sortBy) {
        String orderByClause;
        if ("amount".equalsIgnoreCase(sortBy)) {
            orderByClause = " ORDER BY amount DESC, expense_date DESC";
        } else if ("category".equalsIgnoreCase(sortBy)) {
            orderByClause = " ORDER BY category ASC, expense_date DESC";
        } else {
            // Default: sort by date descending
            orderByClause = " ORDER BY expense_date DESC, expense_id DESC";
        }

        String sql = "SELECT expense_id, user_id, title, amount, category, expense_date, created_at " +
                     "FROM expenses WHERE user_id = ?" + orderByClause;

        List<Expense> list = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Expense exp = new Expense();
                    exp.setId(rs.getInt("expense_id"));
                    exp.setUserId(rs.getInt("user_id"));
                    exp.setTitle(rs.getString("title"));
                    exp.setAmount(rs.getBigDecimal("amount"));
                    exp.setCategory(rs.getString("category"));
                    exp.setExpenseDate(rs.getDate("expense_date"));
                    exp.setCreatedAt(rs.getTimestamp("created_at"));
                    list.add(exp);
                }
            }
        } catch (SQLException e) {
            System.err.println("ExpenseDAO.getExpensesByUser error: " + e.getMessage());
        }
        return list;
    }

    /**
     * Deletes an expense item ONLY if it belongs to the authenticated user.
     * Preventing unauthorized deletion or IDOR attacks.
     *
     * @param expenseId ID of the expense to delete
     * @param userId ID of the current logged-in user
     * @return true if deleted, false if not found or unauthorized
     */
    public boolean deleteExpense(int expenseId, int userId) {
        String sql = "DELETE FROM expenses WHERE expense_id = ? AND user_id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, expenseId);
            ps.setInt(2, userId);

            int affectedRows = ps.executeUpdate();
            return affectedRows > 0;
        } catch (SQLException e) {
            System.err.println("ExpenseDAO.deleteExpense error: " + e.getMessage());
            return false;
        }
    }

    /**
     * Calculates the total amount spent by the given user.
     *
     * @param userId authenticated user ID
     * @return total expenditure as BigDecimal
     */
    public BigDecimal getTotalByUser(int userId) {
        String sql = "SELECT COALESCE(SUM(amount), 0) AS total FROM expenses WHERE user_id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getBigDecimal("total");
                }
            }
        } catch (SQLException e) {
            System.err.println("ExpenseDAO.getTotalByUser error: " + e.getMessage());
        }
        return BigDecimal.ZERO;
    }

    /**
     * Computes the total expenditure per category for the specified user.
     *
     * @param userId authenticated user ID
     * @return Map where key is category name and value is total spent in that category
     */
    public Map<String, BigDecimal> getCategoryTotals(int userId) {
        String sql = "SELECT category, COALESCE(SUM(amount), 0) AS cat_total " +
                     "FROM expenses WHERE user_id = ? " +
                     "GROUP BY category ORDER BY cat_total DESC";

        Map<String, BigDecimal> map = new LinkedHashMap<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    map.put(rs.getString("category"), rs.getBigDecimal("cat_total"));
                }
            }
        } catch (SQLException e) {
            System.err.println("ExpenseDAO.getCategoryTotals error: " + e.getMessage());
        }
        return map;
    }
}

