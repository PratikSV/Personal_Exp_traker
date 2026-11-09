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
import java.util.Arrays;

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

    /**
     * Updates an expense record ONLY if it belongs to the authenticated user.
     * Prevents unauthorized modification (IDOR protection).
     *
     * @param expenseId ID of the expense to update
     * @param userId    ID of the current logged-in user
     * @param title     new title (non-empty, max 100 chars)
     * @param amount    new amount (> 0)
     * @param category  new category (non-empty)
     * @return true if updated, false if not found or unauthorized
     */
    public boolean updateExpense(int expenseId, int userId, String title, BigDecimal amount, String category) {
        String sql = "UPDATE expenses SET title = ?, amount = ?, category = ? " +
                     "WHERE expense_id = ? AND user_id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, title);
            ps.setBigDecimal(2, amount);
            ps.setString(3, category);
            ps.setInt(4, expenseId);
            ps.setInt(5, userId);

            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("ExpenseDAO.updateExpense error: " + e.getMessage());
            return false;
        }
    }

    // =====================================================================
    // Profile / Analytics DAO Methods (Task 2)
    // =====================================================================

    /**
     * Returns all distinct years that have expense records for this user.
     * Used to populate the Year filter dropdown in the Profile view.
     */
    public List<Integer> getExpenseYears(int userId) {
        String sql = "SELECT DISTINCT YEAR(expense_date) AS yr FROM expenses " +
                     "WHERE user_id = ? ORDER BY yr DESC";
        List<Integer> years = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) years.add(rs.getInt("yr"));
            }
        } catch (SQLException e) {
            System.err.println("ExpenseDAO.getExpenseYears error: " + e.getMessage());
        }
        return years;
    }

    /**
     * Returns all distinct categories used by this user.
     * Used to populate the Category filter dropdown in the Profile view.
     */
    public List<String> getUserCategories(int userId) {
        String sql = "SELECT DISTINCT category FROM expenses WHERE user_id = ? ORDER BY category ASC";
        List<String> cats = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) cats.add(rs.getString("category"));
            }
        } catch (SQLException e) {
            System.err.println("ExpenseDAO.getUserCategories error: " + e.getMessage());
        }
        return cats;
    }

    /**
     * Retrieves filtered expenses for the Profile page.
     * Filters are optional — pass null or 0 / empty string to skip a filter.
     * Uses a whitelist for ordering and PreparedStatement for all values.
     *
     * @param userId   authenticated user (always applied)
     * @param year     calendar year filter, 0 = all
     * @param month    month 1-12, 0 = all
     * @param day      day of month 1-31, 0 = all
     * @param category category name, null/empty = all
     * @return list of matching expenses, sorted date desc
     */
    public List<Expense> getExpensesByFilter(int userId, int year, int month, int day, String category) {
        StringBuilder sb = new StringBuilder(
            "SELECT expense_id, user_id, title, amount, category, expense_date, created_at " +
            "FROM expenses WHERE user_id = ?");

        List<Object> params = new ArrayList<>();
        params.add(userId);

        if (year > 0) {
            sb.append(" AND YEAR(expense_date) = ?");
            params.add(year);
        }
        if (month > 0) {
            sb.append(" AND MONTH(expense_date) = ?");
            params.add(month);
        }
        if (day > 0) {
            sb.append(" AND DAY(expense_date) = ?");
            params.add(day);
        }
        if (category != null && !category.trim().isEmpty()) {
            sb.append(" AND category = ?");
            params.add(category.trim());
        }
        sb.append(" ORDER BY expense_date DESC, expense_id DESC");

        List<Expense> list = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sb.toString())) {

            for (int i = 0; i < params.size(); i++) {
                Object v = params.get(i);
                if (v instanceof Integer) ps.setInt(i + 1, (Integer) v);
                else ps.setString(i + 1, (String) v);
            }

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
            System.err.println("ExpenseDAO.getExpensesByFilter error: " + e.getMessage());
        }
        return list;
    }

    /**
     * Returns spending grouped by category for the filtered data set.
     * Same optional filters as getExpensesByFilter.
     */
    public Map<String, BigDecimal> getCategorySummary(int userId, int year, int month, int day, String category) {
        StringBuilder sb = new StringBuilder(
            "SELECT category, COALESCE(SUM(amount), 0) AS cat_total " +
            "FROM expenses WHERE user_id = ?");

        List<Object> params = new ArrayList<>();
        params.add(userId);

        if (year > 0) { sb.append(" AND YEAR(expense_date) = ?"); params.add(year); }
        if (month > 0) { sb.append(" AND MONTH(expense_date) = ?"); params.add(month); }
        if (day > 0) { sb.append(" AND DAY(expense_date) = ?"); params.add(day); }
        if (category != null && !category.trim().isEmpty()) {
            sb.append(" AND category = ?"); params.add(category.trim());
        }
        sb.append(" GROUP BY category ORDER BY cat_total DESC");

        Map<String, BigDecimal> map = new LinkedHashMap<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sb.toString())) {
            for (int i = 0; i < params.size(); i++) {
                Object v = params.get(i);
                if (v instanceof Integer) ps.setInt(i + 1, (Integer) v);
                else ps.setString(i + 1, (String) v);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) map.put(rs.getString("category"), rs.getBigDecimal("cat_total"));
            }
        } catch (SQLException e) {
            System.err.println("ExpenseDAO.getCategorySummary error: " + e.getMessage());
        }
        return map;
    }

    /**
     * Returns spending grouped by month (1-12) for a given year filter.
     * Returns a map of month-number -> total (all 12 slots, 0 if no data).
     */
    public Map<Integer, BigDecimal> getMonthlySummary(int userId, int year, String category) {
        // Initialise all months to zero so charts always have 12 data points
        Map<Integer, BigDecimal> map = new LinkedHashMap<>();
        for (int m = 1; m <= 12; m++) map.put(m, BigDecimal.ZERO);

        StringBuilder sb = new StringBuilder(
            "SELECT MONTH(expense_date) AS mo, COALESCE(SUM(amount), 0) AS mo_total " +
            "FROM expenses WHERE user_id = ?");

        List<Object> params = new ArrayList<>();
        params.add(userId);
        if (year > 0) { sb.append(" AND YEAR(expense_date) = ?"); params.add(year); }
        if (category != null && !category.trim().isEmpty()) {
            sb.append(" AND category = ?"); params.add(category.trim());
        }
        sb.append(" GROUP BY MONTH(expense_date) ORDER BY mo ASC");

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sb.toString())) {
            for (int i = 0; i < params.size(); i++) {
                Object v = params.get(i);
                if (v instanceof Integer) ps.setInt(i + 1, (Integer) v);
                else ps.setString(i + 1, (String) v);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) map.put(rs.getInt("mo"), rs.getBigDecimal("mo_total"));
            }
        } catch (SQLException e) {
            System.err.println("ExpenseDAO.getMonthlySummary error: " + e.getMessage());
        }
        return map;
    }

    /**
     * Returns spending grouped by day-of-month (1-31) for the filtered data set.
     * Used by the Profile bar chart when a month filter is selected.
     * All 31 slots are initialised to zero so charts always have fixed data points.
     */
    public Map<Integer, BigDecimal> getDailySummary(int userId, int year, int month, String category) {
        Map<Integer, BigDecimal> map = new LinkedHashMap<>();
        for (int d = 1; d <= 31; d++) map.put(d, BigDecimal.ZERO);

        StringBuilder sb = new StringBuilder(
            "SELECT DAY(expense_date) AS dy, COALESCE(SUM(amount), 0) AS dy_total " +
            "FROM expenses WHERE user_id = ?");

        List<Object> params = new ArrayList<>();
        params.add(userId);
        if (year > 0) { sb.append(" AND YEAR(expense_date) = ?"); params.add(year); }
        if (month > 0) { sb.append(" AND MONTH(expense_date) = ?"); params.add(month); }
        if (category != null && !category.trim().isEmpty()) {
            sb.append(" AND category = ?"); params.add(category.trim());
        }
        sb.append(" GROUP BY DAY(expense_date) ORDER BY dy ASC");

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sb.toString())) {
            for (int i = 0; i < params.size(); i++) {
                Object v = params.get(i);
                if (v instanceof Integer) ps.setInt(i + 1, (Integer) v);
                else ps.setString(i + 1, (String) v);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) map.put(rs.getInt("dy"), rs.getBigDecimal("dy_total"));
            }
        } catch (SQLException e) {
            System.err.println("ExpenseDAO.getDailySummary error: " + e.getMessage());
        }
        return map;
    }

    /**
     * Alias for getExpenseYears: returns distinct years for the user.
     */
    public List<Integer> getDistinctYears(int userId) {
        return getExpenseYears(userId);
    }

    /**
     * Alias for getUserCategories: returns distinct categories for the user.
     */
    public List<String> getDistinctCategories(int userId) {
        return getUserCategories(userId);
    }

    /**
     * Returns category totals matching the filtered criteria.
     */
    public Map<String, BigDecimal> getCategoryTotals(int userId, int year, int month, int day, String category) {
        return getCategorySummary(userId, year, month, day, category);
    }

    /**
     * Returns monthly totals (1-12) matching the filtered criteria.
     */
    public Map<Integer, BigDecimal> getMonthlyTotals(int userId, int year, String category) {
        return getMonthlySummary(userId, year, category);
    }

    /**
     * Returns daily totals (1-31) matching the filtered criteria.
     */
    public Map<Integer, BigDecimal> getDailyTotals(int userId, int year, int month, String category) {
        return getDailySummary(userId, year, month, category);
    }
}

