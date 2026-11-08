<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>

<%
    // If request has not been processed by ExpenseServlet, redirect to populate data
    if (request.getAttribute("expenses") == null) {
        response.sendRedirect(request.getContextPath() + "/expenses");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - Personal Expense Tracker</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>

    <!-- Main Navigation Bar -->
    <header class="navbar">
        <a href="${pageContext.request.contextPath}/expenses" class="navbar-brand">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <rect x="2" y="4" width="20" height="16" rx="2"/>
                <line x1="12" y1="8" x2="12" y2="16"/>
                <line x1="8" y1="12" x2="16" y2="12"/>
            </svg>
            ExpenseTracker
        </a>
        <div class="navbar-user">
            <span class="user-greeting">
                Welcome, <strong><c:out value="${sessionScope.username}" /></strong>
            </span>
            <form action="${pageContext.request.contextPath}/auth" method="POST" style="display: inline;">
                <input type="hidden" name="action" value="logout">
                <button type="submit" class="btn-logout">Logout</button>
            </form>
        </div>
    </header>

    <!-- Main Content Container -->
    <main class="container">

        <!-- Flash Notifications -->
        <c:if test="${not empty flashSuccess}">
            <div class="alert alert-success">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 6L9 17l-5-5"/></svg>
                <c:out value="${flashSuccess}" />
            </div>
        </c:if>

        <c:if test="${not empty flashError}">
            <div class="alert alert-danger">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                <c:out value="${flashError}" />
            </div>
        </c:if>

        <!-- Summary Stat Cards -->
        <section class="summary-grid">
            <div class="summary-card">
                <span class="card-title">Total Spending</span>
                <span class="card-value">
                    $<fmt:formatNumber value="${totalSpent != null ? totalSpent : 0}" type="number" minFractionDigits="2" maxFractionDigits="2"/>
                </span>
                <span class="card-desc">All-time accumulated expenses</span>
            </div>

            <div class="summary-card">
                <span class="card-title">Total Records</span>
                <span class="card-value">
                    <c:out value="${fn:length(expenses)}" />
                </span>
                <span class="card-desc">Logged expense transactions</span>
            </div>

            <div class="summary-card">
                <span class="card-title">Categories Active</span>
                <span class="card-value">
                    <c:out value="${fn:length(categoryTotals)}" />
                </span>
                <span class="card-desc">Spending categories used</span>
            </div>
        </section>

        <!-- Two Column Dashboard Layout -->
        <div class="dashboard-grid">

            <!-- Left Column: Add Expense Form & Category Breakdown -->
            <aside>
                <!-- Add Expense Card -->
                <div class="card">
                    <div class="card-header-flex">
                        <h2 class="card-heading">Add Expense</h2>
                    </div>

                    <form id="addExpenseForm" action="${pageContext.request.contextPath}/expenses" method="POST" novalidate>
                        <input type="hidden" name="action" value="add">

                        <div class="form-group">
                            <label for="title">Expense Title</label>
                            <input type="text" id="title" name="title" class="form-control"
                                   placeholder="e.g. Grocery shopping" maxlength="100" required>
                            <span id="titleError" class="form-error"></span>
                        </div>

                        <div class="form-group">
                            <label for="amount">Amount ($)</label>
                            <input type="number" id="amount" name="amount" class="form-control"
                                   placeholder="0.00" step="0.01" min="0.01" max="99999999.99" required>
                            <span id="amountError" class="form-error"></span>
                        </div>

                        <div class="form-group">
                            <label for="category">Category</label>
                            <select id="category" name="category" class="form-control" required>
                                <option value="" disabled selected>-- Select Category --</option>
                                <option value="Food">Food & Dining</option>
                                <option value="Transport">Transportation</option>
                                <option value="Housing">Housing & Rent</option>
                                <option value="Utilities">Utilities & Bills</option>
                                <option value="Entertainment">Entertainment</option>
                                <option value="Healthcare">Healthcare</option>
                                <option value="Shopping">Shopping</option>
                                <option value="Education">Education</option>
                                <option value="Other">Other</option>
                            </select>
                            <span id="categoryError" class="form-error"></span>
                        </div>

                        <div class="form-group">
                            <label for="expenseDate">Expense Date</label>
                            <input type="date" id="expenseDate" name="expenseDate" class="form-control" required>
                            <span id="dateError" class="form-error"></span>
                        </div>

                        <button type="submit" class="btn-primary">+ Add Expense</button>
                    </form>
                </div>

                <!-- Category Breakdown Card -->
                <div class="card">
                    <div class="card-header-flex">
                        <h2 class="card-heading">Spending by Category</h2>
                    </div>

                    <c:choose>
                        <c:when test="${not empty categoryTotals}">
                            <ul class="category-list">
                                <c:forEach var="entry" items="${categoryTotals}">
                                    <li class="category-item">
                                        <span class="category-name">
                                            <span class="badge badge-${fn:toLowerCase(entry.key)}">
                                                <c:out value="${entry.key}" />
                                            </span>
                                        </span>
                                        <span class="category-total">
                                            $<fmt:formatNumber value="${entry.value}" type="number" minFractionDigits="2" maxFractionDigits="2"/>
                                        </span>
                                    </li>
                                </c:forEach>
                            </ul>
                        </c:when>
                        <c:otherwise>
                            <div class="empty-state" style="padding: 1rem 0;">
                                <p>No category data available yet.</p>
                            </div>
                        </c:otherwise>
                    </c:choose>
                </div>
            </aside>

            <!-- Right Column: Expenses Table -->
            <section class="card">
                <div class="card-header-flex">
                    <h2 class="card-heading">Recent Expenses</h2>

                    <!-- Sort Controls -->
                    <div class="sort-controls">
                        <span>Sort:</span>
                        <a href="${pageContext.request.contextPath}/expenses?sort=date"
                           class="sort-pill <c:if test="${currentSort == 'date'}">active</c:if>">Date</a>
                        <a href="${pageContext.request.contextPath}/expenses?sort=amount"
                           class="sort-pill <c:if test="${currentSort == 'amount'}">active</c:if>">Amount</a>
                        <a href="${pageContext.request.contextPath}/expenses?sort=category"
                           class="sort-pill <c:if test="${currentSort == 'category'}">active</c:if>">Category</a>
                    </div>
                </div>

                <div class="table-responsive">
                    <c:choose>
                        <c:when test="${not empty expenses}">
                            <table>
                                <thead>
                                    <tr>
                                        <th>Title</th>
                                        <th>Category</th>
                                        <th>Date</th>
                                        <th class="amount-col">Amount</th>
                                        <th style="text-align: center;">Action</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <c:forEach var="exp" items="${expenses}">
                                        <tr>
                                            <td>
                                                <strong><c:out value="${exp.title}" /></strong>
                                            </td>
                                            <td>
                                                <span class="badge badge-${fn:toLowerCase(exp.category)}">
                                                    <c:out value="${exp.category}" />
                                                </span>
                                            </td>
                                            <td>
                                                <fmt:formatDate value="${exp.expenseDate}" pattern="yyyy-MM-dd" />
                                            </td>
                                            <td class="amount-col">
                                                $<fmt:formatNumber value="${exp.amount}" type="number" minFractionDigits="2" maxFractionDigits="2"/>
                                            </td>
                                            <td style="text-align: center;">
                                                <form action="${pageContext.request.contextPath}/expenses" method="POST"
                                                      onsubmit="return confirmDelete('<c:out value="${exp.title}" />');"
                                                      style="display: inline;">
                                                    <input type="hidden" name="action" value="delete">
                                                    <input type="hidden" name="id" value="<c:out value="${exp.id}" />">
                                                    <button type="submit" class="btn-delete" title="Delete expense">Delete</button>
                                                </form>
                                            </td>
                                        </tr>
                                    </c:forEach>
                                </tbody>
                            </table>
                        </c:when>
                        <c:otherwise>
                            <div class="empty-state">
                                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" style="color: var(--text-muted);">
                                    <circle cx="12" cy="12" r="10"/>
                                    <line x1="12" y1="8" x2="12" y2="12"/>
                                    <line x1="12" y1="16" x2="12.01" y2="16"/>
                                </svg>
                                <h3>No Expenses Found</h3>
                                <p>You haven't added any expenses yet. Fill out the form on the left to track your first expense!</p>
                            </div>
                        </c:otherwise>
                    </c:choose>
                </div>
            </section>
        </div>
    </main>

    <script src="${pageContext.request.contextPath}/js/validation.js"></script>
</body>
</html>

