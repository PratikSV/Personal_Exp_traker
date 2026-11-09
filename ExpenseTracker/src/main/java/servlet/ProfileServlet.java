package servlet;

import dao.ExpenseDAO;
import dao.UserDAO;
import model.Expense;
import model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.YearMonth;
import java.util.List;
import java.util.Map;

/**
 * Profile & Analytics Controller Servlet.
 * Fetches user profile, filtered expenses, summary stats, and chart data.
 */
@WebServlet("/profile")
public class ProfileServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private ExpenseDAO expenseDAO;
    private UserDAO userDAO;

    @Override
    public void init() throws ServletException {
        super.init();
        this.expenseDAO = new ExpenseDAO();
        this.userDAO = new UserDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 1. Session / Auth guard
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        int userId = (Integer) session.getAttribute("user_id");

        // 2. Read filter parameters ("" or "all" = no restriction)
        int year = parseFilterInt(request.getParameter("year"));
        int month = parseFilterInt(request.getParameter("month"));
        int day = parseFilterInt(request.getParameter("day"));
        String category = parseFilterString(request.getParameter("category"));

        // 3. Query database via DAOs
        User profileUser = userDAO.getUserById(userId);
        if (profileUser == null) {
            // Fallback to session info if DB query failed
            profileUser = new User();
            profileUser.setId(userId);
            profileUser.setUsername((String) session.getAttribute("username"));
            profileUser.setEmail((String) session.getAttribute("email"));
        }

        List<Expense> expenses = expenseDAO.getExpensesByFilter(userId, year, month, day, category);
        Map<String, BigDecimal> categoryTotals = expenseDAO.getCategoryTotals(userId, year, month, day, category);
        Map<Integer, BigDecimal> monthlyTotals = expenseDAO.getMonthlyTotals(userId, year, category);
        Map<Integer, BigDecimal> dailyTotals = expenseDAO.getDailyTotals(userId, year, month, category);
        List<Integer> distinctYears = expenseDAO.getDistinctYears(userId);
        List<String> distinctCategories = expenseDAO.getDistinctCategories(userId);

        // 4. Compute statistics
        int totalRecords = expenses.size();
        BigDecimal totalSpent = BigDecimal.ZERO;
        for (Expense exp : expenses) {
            if (exp.getAmount() != null) {
                totalSpent = totalSpent.add(exp.getAmount());
            }
        }

        String topCategory = "-";
        BigDecimal maxCategoryAmount = BigDecimal.ZERO;
        for (Map.Entry<String, BigDecimal> entry : categoryTotals.entrySet()) {
            if (entry.getValue() != null && entry.getValue().compareTo(maxCategoryAmount) > 0) {
                maxCategoryAmount = entry.getValue();
                topCategory = entry.getKey();
            }
        }

        // Compute single letter avatar initial
        String userName = profileUser.getUsername();
        String userInitial = (userName != null && !userName.trim().isEmpty())
                ? String.valueOf(Character.toUpperCase(userName.trim().charAt(0)))
                : "U";

        // 5. Build JSON data for Chart.js safely by hand
        StringBuilder catLabelsJson = new StringBuilder("[");
        StringBuilder catValuesJson = new StringBuilder("[");
        boolean firstCat = true;
        for (Map.Entry<String, BigDecimal> entry : categoryTotals.entrySet()) {
            if (!firstCat) {
                catLabelsJson.append(",");
                catValuesJson.append(",");
            }
            catLabelsJson.append("\"").append(escapeJson(entry.getKey())).append("\"");
            BigDecimal val = entry.getValue() != null ? entry.getValue() : BigDecimal.ZERO;
            catValuesJson.append(val.setScale(2, RoundingMode.HALF_UP).toPlainString());
            firstCat = false;
        }
        catLabelsJson.append("]");
        catValuesJson.append("]");

        StringBuilder barLabelsJson = new StringBuilder("[");
        StringBuilder barValuesJson = new StringBuilder("[");
        String barTitle;

        if (month > 0) {
            barTitle = "By Day";
            int maxDays = (year > 0) ? YearMonth.of(year, month).lengthOfMonth() : 31;
            for (int d = 1; d <= maxDays; d++) {
                if (d > 1) {
                    barLabelsJson.append(",");
                    barValuesJson.append(",");
                }
                barLabelsJson.append("\"").append(d).append("\"");
                BigDecimal val = dailyTotals.getOrDefault(d, BigDecimal.ZERO);
                barValuesJson.append(val.setScale(2, RoundingMode.HALF_UP).toPlainString());
            }
        } else {
            barTitle = "By Month";
            String[] monthNames = { "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" };
            for (int m = 1; m <= 12; m++) {
                if (m > 1) {
                    barLabelsJson.append(",");
                    barValuesJson.append(",");
                }
                barLabelsJson.append("\"").append(monthNames[m - 1]).append("\"");
                BigDecimal val = monthlyTotals.getOrDefault(m, BigDecimal.ZERO);
                barValuesJson.append(val.setScale(2, RoundingMode.HALF_UP).toPlainString());
            }
        }
        barLabelsJson.append("]");
        barValuesJson.append("]");

        // 6. Set request attributes
        request.setAttribute("profileUser", profileUser);
        request.setAttribute("userInitial", userInitial);
        request.setAttribute("filteredExpenses", expenses);
        request.setAttribute("totalRecords", totalRecords);
        request.setAttribute("totalSpent", totalSpent);
        request.setAttribute("topCategory", topCategory);

        request.setAttribute("allYears", distinctYears);
        request.setAttribute("allCategories", distinctCategories);

        request.setAttribute("filterYear", year > 0 ? String.valueOf(year) : "");
        request.setAttribute("filterMonth", month > 0 ? String.valueOf(month) : "");
        request.setAttribute("filterDay", day > 0 ? String.valueOf(day) : "");
        request.setAttribute("filterCategory", category != null ? category : "");

        request.setAttribute("catLabelsJson", catLabelsJson.toString());
        request.setAttribute("catValuesJson", catValuesJson.toString());
        request.setAttribute("barLabelsJson", barLabelsJson.toString());
        request.setAttribute("barValuesJson", barValuesJson.toString());
        request.setAttribute("barTitle", barTitle);

        request.getRequestDispatcher("/profile.jsp").forward(request, response);
    }

    private int parseFilterInt(String val) {
        if (val == null || val.trim().isEmpty() || "all".equalsIgnoreCase(val.trim())) {
            return 0;
        }
        try {
            int parsed = Integer.parseInt(val.trim());
            return Math.max(parsed, 0);
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    private String parseFilterString(String val) {
        if (val == null || val.trim().isEmpty() || "all".equalsIgnoreCase(val.trim())) {
            return null;
        }
        return val.trim();
    }

    private String escapeJson(String s) {
        if (s == null)
            return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\b", "\\b")
                .replace("\f", "\\f")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}
