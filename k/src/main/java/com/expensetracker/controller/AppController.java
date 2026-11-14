package com.expensetracker.controller;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.*;
import jakarta.servlet.http.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
@SuppressWarnings("null")
public class AppController {
    private final JdbcTemplate db;
    private final PasswordEncoder encoder;

    public AppController(JdbcTemplate db, PasswordEncoder encoder) {
        this.db = db;
        this.encoder = encoder;
    }

    @InitBinder
    public void initBinder(org.springframework.web.bind.WebDataBinder binder) {
        binder.registerCustomEditor(String.class,
                new org.springframework.beans.propertyeditors.StringTrimmerEditor(true));
    }

    @ModelAttribute("ctx")
    public String context(HttpServletRequest req) {
        return req.getContextPath();
    }

    private void csrf(HttpSession s) {
        if (s.getAttribute("csrf") == null)
            s.setAttribute("csrf", UUID.randomUUID().toString());
    }

    private boolean validCsrf(HttpSession s, String token) {
        return s != null && token != null && token.equals(s.getAttribute("csrf"));
    }

    private Long uid(HttpSession s) {
        Object id = s == null ? null : s.getAttribute("userId");
        return id instanceof Long ? (Long) id : null;
    }

    private String userName(HttpSession s) {
        Object n = s.getAttribute("userName");
        return n == null ? "" : n.toString();
    }

    @GetMapping({ "/", "/login" })
    public String loginPage(HttpSession s, Model m) {
        if (uid(s) != null)
            return "redirect:/dashboard";
        csrf(s);
        m.addAttribute("csrf", s.getAttribute("csrf"));
        return "login";
    }

    @PostMapping("/login")
    public String login(@RequestParam String email, @RequestParam String password, @RequestParam String csrfToken,
            HttpServletRequest req, Model m) {
        HttpSession old = req.getSession(false);
        if (!validCsrf(old, csrfToken))
            return "redirect:/login";
        List<Map<String, Object>> rows = db.queryForList(
                "SELECT user_id,full_name,password_hash FROM users WHERE email=?", email.trim().toLowerCase());
        if (rows.isEmpty() || !encoder.matches(password, (String) rows.get(0).get("password_hash"))) {
            m.addAttribute("error", "Email or password is incorrect.");
            m.addAttribute("csrf", old.getAttribute("csrf"));
            return "login";
        }
        req.changeSessionId();
        HttpSession s = req.getSession();
        s.setAttribute("userId", ((Number) rows.get(0).get("user_id")).longValue());
        s.setAttribute("userName", rows.get(0).get("full_name"));
        csrf(s);
        return "redirect:/dashboard";
    }

    @GetMapping("/register")
    public String registerPage(HttpSession s, Model m) {
        csrf(s);
        m.addAttribute("csrf", s.getAttribute("csrf"));
        return "register";
    }

    @PostMapping("/register")
    public String register(@RequestParam String fullName, @RequestParam String email, @RequestParam String password,
            @RequestParam String confirmPassword, @RequestParam String csrfToken, HttpSession s, Model m) {
        if (!validCsrf(s, csrfToken)) {
            m.addAttribute("error", "Your form expired. Please try again.");
        } else if (fullName.trim().isEmpty() || fullName.length() > 120
                || !email.matches("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$") || email.length() > 190) {
            m.addAttribute("error", "Enter a valid name and email address.");
        } else if (password.length() < 8 || password.length() > 72) {
            m.addAttribute("error", "Password must be between 8 and 72 characters.");
        } else if (!password.equals(confirmPassword)) {
            m.addAttribute("error", "Passwords do not match.");
        } else {
            try {
                db.update("INSERT INTO users(full_name,email,password_hash) VALUES(?,?,?)", fullName.trim(),
                        email.trim().toLowerCase(), encoder.encode(password));
                Long id = db.queryForObject("SELECT user_id FROM users WHERE email=?", Long.class,
                        email.trim().toLowerCase());
                String[] expense = { "Food", "Travel", "Shopping", "Bills", "Entertainment", "Healthcare", "Education",
                        "Rent", "Personal Care", "Other" };
                String[] income = { "Salary", "Freelance", "Business", "Investment", "Other Income" };
                for (String c : expense)
                    db.update("INSERT INTO categories(user_id,category_name,category_type,is_default) VALUES(?,?,?,1)",
                            id, c, "EXPENSE");
                for (String c : income)
                    db.update("INSERT INTO categories(user_id,category_name,category_type,is_default) VALUES(?,?,?,1)",
                            id, c, "INCOME");
                m.addAttribute("success", "Account created! You can now sign in.");
            } catch (org.springframework.dao.DuplicateKeyException ex) {
                m.addAttribute("error", "An account with this email already exists.");
            } catch (Exception ex) {
                m.addAttribute("error", "Could not create account. Check database connection and try again.");
            }
        }
        m.addAttribute("csrf", s.getAttribute("csrf"));
        return "register";
    }

    @PostMapping("/logout")
    public String logout(HttpServletRequest req, @RequestParam String csrfToken) {
        HttpSession s = req.getSession(false);
        if (validCsrf(s, csrfToken))
            s.invalidate();
        return "redirect:/login";
    }

    @GetMapping("/dashboard")
    public String dashboard(
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate,
            @RequestParam(required = false, defaultValue = "ALL") String type,
            @RequestParam(required = false) Long categoryId,
            HttpSession s, Model m) {
        if (uid(s) == null)
            return "redirect:/login";
        long id = uid(s);

        // Parse optional date filters
        LocalDate start = null;
        LocalDate end = null;
        if (startDate != null && !startDate.trim().isEmpty()) {
            try {
                start = LocalDate.parse(startDate.trim());
            } catch (Exception ignored) {
            }
        }
        if (endDate != null && !endDate.trim().isEmpty()) {
            try {
                end = LocalDate.parse(endDate.trim());
            } catch (Exception ignored) {
            }
        }

        String filterType = "ALL";
        if ("EXPENSE".equalsIgnoreCase(type)) {
            filterType = "EXPENSE";
        } else if ("INCOME".equalsIgnoreCase(type)) {
            filterType = "INCOME";
        }

        Long filterCategory = (categoryId != null && categoryId > 0) ? categoryId : null;

        // 1. Overall Account Totals (remain constant regardless of chart filters)
        BigDecimal income = db.queryForObject(
                "SELECT COALESCE(SUM(amount), 0) FROM income WHERE user_id = ?",
                BigDecimal.class, id);
        if (income == null)
            income = BigDecimal.ZERO;

        BigDecimal expense = db.queryForObject(
                "SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE user_id = ?",
                BigDecimal.class, id);
        if (expense == null)
            expense = BigDecimal.ZERO;

        BigDecimal balance = income.subtract(expense);

        // 2. Cash Flow Timeline (Line Graph - filtered by date, type, category)
        boolean groupByDay = false;
        if (start != null && end != null && ChronoUnit.DAYS.between(start, end) <= 31) {
            groupByDay = true;
        }

        String dateFormat = groupByDay ? "%d %b" : "%b %Y";
        String dateKey = groupByDay ? "%Y-%m-%d" : "%Y-%m";

        StringBuilder flowSql = new StringBuilder(
                "SELECT period_key, period_label, SUM(inc) AS income_total, SUM(exp) AS expense_total FROM (");

        // Income subquery
        flowSql.append("SELECT income_date AS d, DATE_FORMAT(income_date, '").append(dateFormat)
                .append("') AS period_label, DATE_FORMAT(income_date, '").append(dateKey)
                .append("') AS period_key, amount AS inc, 0 AS exp FROM income WHERE user_id = ?");
        List<Object> flowParams = new ArrayList<>();
        flowParams.add(id);
        if (start != null) {
            flowSql.append(" AND income_date >= ?");
            flowParams.add(start);
        } else if (end == null) {
            flowSql.append(" AND income_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)");
        }
        if (end != null) {
            flowSql.append(" AND income_date <= ?");
            flowParams.add(end);
        }

        flowSql.append(" UNION ALL ");

        // Expense subquery
        flowSql.append("SELECT expense_date AS d, DATE_FORMAT(expense_date, '").append(dateFormat)
                .append("') AS period_label, DATE_FORMAT(expense_date, '").append(dateKey)
                .append("') AS period_key, 0 AS inc, amount AS exp FROM expenses WHERE user_id = ?");
        flowParams.add(id);
        if (start != null) {
            flowSql.append(" AND expense_date >= ?");
            flowParams.add(start);
        } else if (end == null) {
            flowSql.append(" AND expense_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)");
        }
        if (end != null) {
            flowSql.append(" AND expense_date <= ?");
            flowParams.add(end);
        }
        if (filterCategory != null) {
            flowSql.append(" AND category_id = ?");
            flowParams.add(filterCategory);
        }

        flowSql.append(") x GROUP BY period_key, period_label ORDER BY period_key ASC");

        List<Map<String, Object>> monthly = db.queryForList(flowSql.toString(), flowParams.toArray());

        // 4. Spending / Category Breakdown (Pie Chart)
        List<Map<String, Object>> categories;
        if ("INCOME".equals(filterType)) {
            StringBuilder catSql = new StringBuilder(
                    "SELECT COALESCE(c.category_name, 'Uncategorised') AS category_name, COALESCE(SUM(i.amount), 0) AS total "
                            +
                            "FROM income i " +
                            "LEFT JOIN categories c ON c.category_id = i.category_id " +
                            "WHERE i.user_id = ?");
            List<Object> catParams = new ArrayList<>();
            catParams.add(id);
            if (start != null) {
                catSql.append(" AND i.income_date >= ?");
                catParams.add(start);
            }
            if (end != null) {
                catSql.append(" AND i.income_date <= ?");
                catParams.add(end);
            }
            catSql.append(" GROUP BY COALESCE(c.category_name, 'Uncategorised') HAVING total > 0 ORDER BY total DESC");
            categories = db.queryForList(catSql.toString(), catParams.toArray());
        } else {
            StringBuilder catSql = new StringBuilder(
                    "SELECT COALESCE(c.category_name, 'Uncategorised') AS category_name, COALESCE(SUM(e.amount), 0) AS total "
                            +
                            "FROM expenses e " +
                            "LEFT JOIN categories c ON c.category_id = e.category_id " +
                            "WHERE e.user_id = ?");
            List<Object> catParams = new ArrayList<>();
            catParams.add(id);
            if (start != null) {
                catSql.append(" AND e.expense_date >= ?");
                catParams.add(start);
            }
            if (end != null) {
                catSql.append(" AND e.expense_date <= ?");
                catParams.add(end);
            }
            if (filterCategory != null) {
                catSql.append(" AND e.category_id = ?");
                catParams.add(filterCategory);
            }
            catSql.append(" GROUP BY COALESCE(c.category_name, 'Uncategorised') HAVING total > 0 ORDER BY total DESC");
            categories = db.queryForList(catSql.toString(), catParams.toArray());
        }

        // 5. Recent Activity Table (Filtered)
        StringBuilder recSql = new StringBuilder();
        List<Object> recParams = new ArrayList<>();

        if ("INCOME".equals(filterType)) {
            recSql.append(
                    "SELECT title, amount, income_date AS tx_date, 'Income' AS kind FROM income WHERE user_id = ?");
            recParams.add(id);
            if (start != null) {
                recSql.append(" AND income_date >= ?");
                recParams.add(start);
            }
            if (end != null) {
                recSql.append(" AND income_date <= ?");
                recParams.add(end);
            }
            recSql.append(" ORDER BY tx_date DESC, income_id DESC LIMIT 10");
        } else if ("EXPENSE".equals(filterType)) {
            recSql.append(
                    "SELECT title, amount, expense_date AS tx_date, 'Expense' AS kind FROM expenses WHERE user_id = ?");
            recParams.add(id);
            if (start != null) {
                recSql.append(" AND expense_date >= ?");
                recParams.add(start);
            }
            if (end != null) {
                recSql.append(" AND expense_date <= ?");
                recParams.add(end);
            }
            if (filterCategory != null) {
                recSql.append(" AND category_id = ?");
                recParams.add(filterCategory);
            }
            recSql.append(" ORDER BY tx_date DESC, expense_id DESC LIMIT 10");
        } else {
            recSql.append("SELECT title, amount, tx_date, kind FROM (");
            recSql.append(
                    "SELECT title, amount, expense_date AS tx_date, 'Expense' AS kind, expense_id AS id FROM expenses WHERE user_id = ?");
            recParams.add(id);
            if (start != null) {
                recSql.append(" AND expense_date >= ?");
                recParams.add(start);
            }
            if (end != null) {
                recSql.append(" AND expense_date <= ?");
                recParams.add(end);
            }
            if (filterCategory != null) {
                recSql.append(" AND category_id = ?");
                recParams.add(filterCategory);
            }

            recSql.append(" UNION ALL ");

            recSql.append(
                    "SELECT title, amount, income_date AS tx_date, 'Income' AS kind, income_id AS id FROM income WHERE user_id = ?");
            recParams.add(id);
            if (start != null) {
                recSql.append(" AND income_date >= ?");
                recParams.add(start);
            }
            if (end != null) {
                recSql.append(" AND income_date <= ?");
                recParams.add(end);
            }

            recSql.append(") x ORDER BY tx_date DESC, id DESC LIMIT 10");
        }

        List<Map<String, Object>> recent = db.queryForList(recSql.toString(), recParams.toArray());

        // 6. User's categories for the filter dropdown
        List<Map<String, Object>> allCategories = db.queryForList(
                "SELECT category_id, category_name, category_type FROM categories WHERE user_id = ? ORDER BY category_type DESC, category_name ASC",
                id);

        m.addAttribute("name", userName(s));
        m.addAttribute("income", income);
        m.addAttribute("expense", expense);
        m.addAttribute("balance", balance);
        m.addAttribute("recent", recent);
        m.addAttribute("monthly", monthly);
        m.addAttribute("categories", categories);
        m.addAttribute("allCategories", allCategories);

        // Preserve filter form values
        m.addAttribute("filterStartDate", startDate != null ? startDate.trim() : "");
        m.addAttribute("filterEndDate", endDate != null ? endDate.trim() : "");
        m.addAttribute("filterType", filterType);
        m.addAttribute("filterCategoryId", filterCategory != null ? filterCategory : "");
        m.addAttribute("isFiltered",
                (start != null || end != null || !"ALL".equals(filterType) || filterCategory != null));

        csrf(s);
        m.addAttribute("csrf", s.getAttribute("csrf"));
        return "dashboard";
    }

    @GetMapping("/transactions")
    public String transactions(HttpSession s, Model m) {
        if (uid(s) == null)
            return "redirect:/login";
        long id = uid(s);
        m.addAttribute("expenses", db.queryForList(
                "SELECT e.expense_id id,e.title,e.amount,e.expense_date tx_date,COALESCE(c.category_name,'Uncategorised') category FROM expenses e LEFT JOIN categories c ON e.category_id=c.category_id WHERE e.user_id=? ORDER BY e.expense_date DESC,e.expense_id DESC",
                id));
        m.addAttribute("incomes", db.queryForList(
                "SELECT i.income_id id,i.title,i.amount,i.income_date tx_date,COALESCE(c.category_name,'Uncategorised') category FROM income i LEFT JOIN categories c ON i.category_id=c.category_id WHERE i.user_id=? ORDER BY i.income_date DESC,i.income_id DESC",
                id));
        m.addAttribute("csrf", s.getAttribute("csrf"));
        m.addAttribute("categories", db.queryForList(
                "SELECT category_id,category_name,category_type FROM categories WHERE user_id=? ORDER BY category_name",
                id));
        return "transactions";
    }

    @PostMapping("/transaction/save")
    public String save(@RequestParam String type, @RequestParam String title, @RequestParam String amount,
            @RequestParam String date, @RequestParam(required = false) String categoryId,
            @RequestParam String csrfToken,
            HttpSession s, Model m) {
        if (uid(s) == null)
            return "redirect:/login";
        if (!validCsrf(s, csrfToken))
            return "redirect:/transactions";
        try {
            BigDecimal value = new BigDecimal(amount);
            LocalDate day = LocalDate.parse(date);
            if (value.signum() <= 0 || value.scale() > 2 || title.trim().isEmpty() || title.length() > 150)
                throw new IllegalArgumentException();
            long id = uid(s);
            Long cat = null;
            if (categoryId != null && !categoryId.trim().isEmpty()) {
                long cId = Long.parseLong(categoryId.trim());
                if (cId > 0) {
                    Integer count = db.queryForObject(
                            "SELECT COUNT(*) FROM categories WHERE category_id=? AND user_id=?",
                            Integer.class, cId, id);
                    if (count == null || count == 0)
                        throw new IllegalArgumentException();
                    cat = cId;
                }
            }
            if ("INCOME".equals(type)) {
                db.update("INSERT INTO income(user_id,category_id,title,amount,income_date) VALUES(?,?,?,?,?)", id, cat,
                        title.trim(), value, day);
            } else {
                db.update("INSERT INTO expenses(user_id,category_id,title,amount,expense_date) VALUES(?,?,?,?,?)", id,
                        cat, title.trim(), value, day);
            }
        } catch (Exception ex) {
            s.setAttribute("flashError", "Please enter a valid transaction.");
        }
        return "redirect:/transactions";
    }

    @PostMapping("/transaction/delete")
    public String delete(@RequestParam String type, @RequestParam long id, @RequestParam String csrfToken,
            HttpSession s) {
        if (uid(s) == null)
            return "redirect:/login";
        if (!validCsrf(s, csrfToken))
            return "redirect:/transactions";
        if ("INCOME".equals(type))
            db.update("DELETE FROM income WHERE income_id=? AND user_id=?", id, uid(s));
        else
            db.update("DELETE FROM expenses WHERE expense_id=? AND user_id=?", id, uid(s));
        return "redirect:/transactions";
    }

    @GetMapping("/budgets")
    public String budgets(HttpSession s, Model m) {
        if (uid(s) == null)
            return "redirect:/login";
        long id = uid(s);
        m.addAttribute("budgets", db.queryForList(
                "SELECT b.budget_id,b.budget_name,b.amount,b.budget_month,COALESCE(SUM(e.amount),0) spent FROM budgets b LEFT JOIN expenses e ON e.user_id=b.user_id AND e.category_id=b.category_id AND e.expense_date>=b.budget_month AND e.expense_date<DATE_ADD(b.budget_month,INTERVAL 1 MONTH) WHERE b.user_id=? GROUP BY b.budget_id,b.budget_name,b.amount,b.budget_month ORDER BY b.budget_month DESC",
                id));
        m.addAttribute("categories", db.queryForList(
                "SELECT category_id,category_name FROM categories WHERE user_id=? AND category_type='EXPENSE' ORDER BY category_name",
                id));
        m.addAttribute("csrf", s.getAttribute("csrf"));
        return "budgets";
    }

    @PostMapping("/budget/save")
    public String saveBudget(@RequestParam String name, @RequestParam String amount, @RequestParam String month,
            @RequestParam long categoryId, @RequestParam String csrfToken, HttpSession s) {
        if (uid(s) == null)
            return "redirect:/login";
        if (!validCsrf(s, csrfToken))
            return "redirect:/budgets";
        try {
            BigDecimal value = new BigDecimal(amount);
            LocalDate first = LocalDate.parse(month + "-01");
            if (value.signum() <= 0 || value.scale() > 2)
                throw new IllegalArgumentException();
            Integer valid = db.queryForObject(
                    "SELECT COUNT(*) FROM categories WHERE category_id=? AND user_id=? AND category_type='EXPENSE'",
                    Integer.class, categoryId, uid(s));
            if (valid != null && valid > 0)
                db.update(
                        "INSERT INTO budgets(user_id,category_id,budget_name,amount,budget_month) VALUES(?,?,?,?,?) ON DUPLICATE KEY UPDATE budget_name=VALUES(budget_name),amount=VALUES(amount)",
                        uid(s), categoryId, name.trim(), value, first);
        } catch (Exception ignored) {
        }
        return "redirect:/budgets";
    }

    @PostMapping("/budget/delete")
    public String deleteBudget(@RequestParam long id, @RequestParam String csrfToken, HttpSession s) {
        if (uid(s) == null)
            return "redirect:/login";
        if (validCsrf(s, csrfToken))
            db.update("DELETE FROM budgets WHERE budget_id=? AND user_id=?", id, uid(s));
        return "redirect:/budgets";
    }
}