package servlet;

import dao.ExpenseDAO;
import model.Expense;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.YearMonth;
import java.util.List;
import java.util.Map;

/**
 * =====================================================================
 * Task 2 – Profile & Analytics Controller
 * Project: Personal Expense Tracker
 * =====================================================================
 * Reads optional filter params (year, month, day, category), delegates
 * to ExpenseDAO, then forwards to profile.jsp with:
 *   - filteredExpenses   : List<Expense>
 *   - categoryData       : Map<String,BigDecimal>  (for Pie chart)
 *   - monthlyData        : Map<Integer,BigDecimal> (for Bar chart, 12 slots)
 *   - totalFiltered      : BigDecimal
 *   - allYears           : List<Integer>
 *   - allCategories      : List<String>
 *   - filter.*           : echoed back so the form remembers selections
 *
 * No JSON library is used — chart data is serialised to JSON strings
 * manually (simple numeric/string values only, XSS-safe).
 */
@WebServlet("/profile")
public class ProfileServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private ExpenseDAO expenseDAO;

    @Override
    public void init() throws ServletException {
        super.init();
        this.expenseDAO = new ExpenseDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // ---- Auth guard ----
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        int userId = (Integer) session.getAttribute("user_id");

        // ---- Parse filter params (all optional) ----
        int year     = parseIntParam(request.getParameter("year"),  0);
        int month    = parseIntParam(request.getParameter("month"), 0);
        int day      = parseIntParam(request.getParameter("day"),   0);
        String category = request.getParameter("category");
        if (category != null && category.trim().isEmpty()) category = null;

        // ---- DAO calls ----
        List<Expense> expenses = expenseDAO.getExpensesByFilter(userId, year, month, day, category);
        Map<String, BigDecimal> catData     = expenseDAO.getCategorySummary(userId, year, month, day, category);
        Map<Integer, BigDecimal> monthlyData = expenseDAO.getMonthlySummary(userId, year, category);
        Map<Integer, BigDecimal> dailyData   = expenseDAO.getDailySummary(userId, year, month, category);
        List<Integer> allYears              = expenseDAO.getExpenseYears(userId);
        List<String>  allCategories         = expenseDAO.getUserCategories(userId);

        // ---- Compute total for filtered set ----
        BigDecimal total = BigDecimal.ZERO;
        for (Expense e : expenses) total = total.add(e.getAmount());

        // ---- Build JSON strings for Chart.js (manual, no library) ----
        // Category pie: { labels:[...], data:[...] }
        StringBuilder catLabels = new StringBuilder("[");
        StringBuilder catValues = new StringBuilder("[");
        boolean first = true;
        for (Map.Entry<String, BigDecimal> e : catData.entrySet()) {
            if (!first) { catLabels.append(","); catValues.append(","); }
            catLabels.append("\"").append(escapeJson(e.getKey())).append("\"");
            catValues.append(e.getValue().toPlainString());
            first = false;
        }
        catLabels.append("]");
        catValues.append("]");

        // Bar chart: grouped by day when a month is selected, otherwise by month.
        // Labels and values are emitted as parallel JSON arrays.
        StringBuilder barLabels = new StringBuilder("[");
        StringBuilder barValues = new StringBuilder("[");
        String barTitle;
        if (month > 0) {
            barTitle = "By Day";
            int maxDay = (year > 0)
                    ? YearMonth.of(year, month).lengthOfMonth()
                    : 31;
            for (int d = 1; d <= maxDay; d++) {
                if (d > 1) { barLabels.append(","); barValues.append(","); }
                barLabels.append("\"").append(d).append("\"");
                barValues.append(dailyData.getOrDefault(d, BigDecimal.ZERO).toPlainString());
            }
        } else {
            barTitle = "By Month";
            String[] monthNames = {"Jan","Feb","Mar","Apr","May","Jun",
                                   "Jul","Aug","Sep","Oct","Nov","Dec"};
            for (int m = 1; m <= 12; m++) {
                if (m > 1) { barLabels.append(","); barValues.append(","); }
                barLabels.append("\"").append(monthNames[m - 1]).append("\"");
                barValues.append(monthlyData.getOrDefault(m, BigDecimal.ZERO).toPlainString());
            }
        }
        barLabels.append("]");
        barValues.append("]");

        // ---- Set request attributes ----
        request.setAttribute("filteredExpenses", expenses);
        request.setAttribute("categoryData",    catData);
        request.setAttribute("totalFiltered",   total);
        request.setAttribute("allYears",        allYears);
        request.setAttribute("allCategories",   allCategories);

        // Echo filters back to view for pre-selecting dropdowns
        request.setAttribute("filterYear",     year > 0  ? String.valueOf(year)  : "");
        request.setAttribute("filterMonth",    month > 0 ? String.valueOf(month) : "");
        request.setAttribute("filterDay",      day > 0   ? String.valueOf(day)   : "");
        request.setAttribute("filterCategory", category != null ? category : "");

        // JSON for charts
        request.setAttribute("catLabelsJson",  catLabels.toString());
        request.setAttribute("catValuesJson",  catValues.toString());
        request.setAttribute("barLabelsJson",  barLabels.toString());
        request.setAttribute("barValuesJson",  barValues.toString());
        request.setAttribute("barTitle",       barTitle);

        request.getRequestDispatcher("/profile.jsp").forward(request, response);
    }

    // ---- Helpers ----

    private int parseIntParam(String val, int defaultVal) {
        if (val == null || val.trim().isEmpty()) return defaultVal;
        try {
            int v = Integer.parseInt(val.trim());
            return v > 0 ? v : defaultVal;
        } catch (NumberFormatException e) {
            return defaultVal;
        }
    }

    /** Minimal JSON string escaper — only needed for category names. */
    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}

