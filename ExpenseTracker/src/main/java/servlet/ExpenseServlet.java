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
import java.sql.Date;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Map;

/**
 * =====================================================================
 * Member 5 Deliverable: Expense Controller Servlet
 * Project: Personal Expense Tracker
 * =====================================================================
 * Handles listing, adding, and deleting user expenses.
 * STRICT SECURITY:
 * user_id is ALWAYS fetched from the active HttpSession, NEVER accepted
 * from client request parameters. Implements the Post-Redirect-Get (PRG) pattern.
 */
@WebServlet("/expenses")
public class ExpenseServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private static final BigDecimal MAX_AMOUNT = new BigDecimal("99999999.99");
    private ExpenseDAO expenseDAO;

    @Override
    public void init() throws ServletException {
        super.init();
        this.expenseDAO = new ExpenseDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        // Always read user_id from session
        int userId = (Integer) session.getAttribute("user_id");

        // Optional sort parameter: "date", "amount", "category"
        String sortBy = request.getParameter("sort");
        if (sortBy == null || sortBy.trim().isEmpty()) {
            sortBy = "date";
        }

        // Fetch data scoped to the current user
        List<Expense> expenses = expenseDAO.getExpensesByUser(userId, sortBy);
        BigDecimal totalSpent = expenseDAO.getTotalByUser(userId);
        Map<String, BigDecimal> categoryTotals = expenseDAO.getCategoryTotals(userId);

        // Flash message handling (from previous POST actions)
        String flashSuccess = (String) session.getAttribute("flashSuccess");
        String flashError = (String) session.getAttribute("flashError");
        if (flashSuccess != null) {
            request.setAttribute("flashSuccess", flashSuccess);
            session.removeAttribute("flashSuccess");
        }
        if (flashError != null) {
            request.setAttribute("flashError", flashError);
            session.removeAttribute("flashError");
        }

        // Pass data to index.jsp view
        request.setAttribute("expenses", expenses);
        request.setAttribute("totalSpent", totalSpent);
        request.setAttribute("categoryTotals", categoryTotals);
        request.setAttribute("currentSort", sortBy);

        request.getRequestDispatcher("/index.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        int userId = (Integer) session.getAttribute("user_id");
        String action = request.getParameter("action");
        if (action == null) {
            action = "";
        }

        switch (action) {
            case "add":
                handleAddExpense(request, response, session, userId);
                break;
            case "delete":
                handleDeleteExpense(request, response, session, userId);
                break;
            default:
                response.sendRedirect(request.getContextPath() + "/expenses");
                break;
        }
    }

    /**
     * Adds an expense with thorough server-side validations.
     */
    private void handleAddExpense(HttpServletRequest request, HttpServletResponse response,
                                  HttpSession session, int userId) throws IOException {
        String title = request.getParameter("title");
        String amountStr = request.getParameter("amount");
        String category = request.getParameter("category");
        String dateStr = request.getParameter("expenseDate");

        title = (title != null) ? title.trim() : "";
        amountStr = (amountStr != null) ? amountStr.trim() : "";
        category = (category != null) ? category.trim() : "";
        dateStr = (dateStr != null) ? dateStr.trim() : "";

        // 1. Title validation
        if (title.isEmpty() || title.length() > 100) {
            session.setAttribute("flashError", "Expense title is required and cannot exceed 100 characters.");
            response.sendRedirect(request.getContextPath() + "/expenses");
            return;
        }

        // 2. Amount validation
        BigDecimal amount;
        try {
            amount = new BigDecimal(amountStr);
            if (amount.compareTo(BigDecimal.ZERO) <= 0) {
                session.setAttribute("flashError", "Amount must be strictly greater than 0.00.");
                response.sendRedirect(request.getContextPath() + "/expenses");
                return;
            }
            if (amount.compareTo(MAX_AMOUNT) > 0) {
                session.setAttribute("flashError", "Amount exceeds the maximum allowed limit (99,999,999.99).");
                response.sendRedirect(request.getContextPath() + "/expenses");
                return;
            }
        } catch (NumberFormatException | ArithmeticException e) {
            session.setAttribute("flashError", "Please enter a valid numeric amount (e.g. 49.99).");
            response.sendRedirect(request.getContextPath() + "/expenses");
            return;
        }

        // 3. Category validation
        if (category.isEmpty() || category.length() > 50) {
            session.setAttribute("flashError", "Please select a valid category.");
            response.sendRedirect(request.getContextPath() + "/expenses");
            return;
        }

        // 4. Date validation (yyyy-MM-dd)
        Date expenseDate;
        try {
            LocalDate parsedDate = LocalDate.parse(dateStr);
            expenseDate = Date.valueOf(parsedDate);
        } catch (DateTimeParseException | IllegalArgumentException e) {
            session.setAttribute("flashError", "Please provide a valid date in yyyy-MM-dd format.");
            response.sendRedirect(request.getContextPath() + "/expenses");
            return;
        }

        // Construct model and persist
        Expense expense = new Expense(userId, title, amount, category, expenseDate);
        boolean success = expenseDAO.addExpense(expense);

        if (success) {
            session.setAttribute("flashSuccess", "Expense '" + title + "' added successfully!");
        } else {
            session.setAttribute("flashError", "Failed to add expense due to a database error.");
        }

        // Post-Redirect-Get pattern
        response.sendRedirect(request.getContextPath() + "/expenses");
    }

    /**
     * Deletes an expense item ensuring it belongs to the authenticated user.
     */
    private void handleDeleteExpense(HttpServletRequest request, HttpServletResponse response,
                                     HttpSession session, int userId) throws IOException {
        String idStr = request.getParameter("id");
        if (idStr == null || idStr.trim().isEmpty()) {
            session.setAttribute("flashError", "Invalid expense ID provided.");
            response.sendRedirect(request.getContextPath() + "/expenses");
            return;
        }

        try {
            int expenseId = Integer.parseInt(idStr.trim());
            // Filtered by both expenseId AND authenticated userId
            boolean deleted = expenseDAO.deleteExpense(expenseId, userId);

            if (deleted) {
                session.setAttribute("flashSuccess", "Expense deleted successfully.");
            } else {
                session.setAttribute("flashError", "Expense not found or you are not authorized to delete it.");
            }
        } catch (NumberFormatException e) {
            session.setAttribute("flashError", "Invalid expense ID format.");
        }

        // Post-Redirect-Get pattern
        response.sendRedirect(request.getContextPath() + "/expenses");
    }
}

