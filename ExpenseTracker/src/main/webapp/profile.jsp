<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%--
 =====================================================================
 Profile & Analytics View (rebuilt layout)
 Project: Personal Expense Tracker
 =====================================================================
--%>
<%
    if (session.getAttribute("user_id") == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // ---- Avatar initials from username (max 2 letters) ----
    String username = (String) session.getAttribute("username");
    if (username == null) username = "U";
    StringBuilder ini = new StringBuilder();
    for (String part : username.trim().split("[^A-Za-z0-9]+")) {
        if (!part.isEmpty() && ini.length() < 2) {
            ini.append(Character.toUpperCase(part.charAt(0)));
        }
    }
    if (ini.length() == 0) ini.append(Character.toUpperCase(username.charAt(0)));
    request.setAttribute("userInitials", ini.toString());

    // ---- Top spending category for the stat row (respects filters) ----
    String topCategory = "—";
    Object cd = request.getAttribute("categoryData");
    if (cd instanceof java.util.Map) {
        java.util.Map<?, ?> catMap = (java.util.Map<?, ?>) cd;
        java.math.BigDecimal maxVal = null;
        String topKey = null;
        for (java.util.Map.Entry<?, ?> e : catMap.entrySet()) {
            java.math.BigDecimal v = (java.math.BigDecimal) e.getValue();
            if (topKey == null || (maxVal != null && v.compareTo(maxVal) > 0)) {
                maxVal = v;
                topKey = (String) e.getKey();
            }
        }
        if (topKey != null) topCategory = topKey;
    }
    request.setAttribute("topCategory", topCategory);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Profile &amp; Analytics - Personal Expense Tracker</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <!-- Chart.js via CDN -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.3/dist/chart.umd.min.js"></script>
</head>
<body>

    <!-- Navbar (same as index.jsp, Profile highlighted) -->
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
            <a href="${pageContext.request.contextPath}/expenses" class="nav-link">Dashboard</a>
            <a href="${pageContext.request.contextPath}/profile" class="nav-link active">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/></svg>
                Profile
            </a>
            <form action="${pageContext.request.contextPath}/auth" method="POST" style="display:inline;">
                <input type="hidden" name="action" value="logout">
                <button type="submit" class="btn-logout">Logout</button>
            </form>
        </div>
    </header>

    <main class="container profile-page">
        <div class="profile-layout">

            <!-- ================= LEFT SIDEBAR ================= -->
            <aside class="profile-sidebar">

                <!-- Profile Info Card -->
                <div class="profile-card profile-info-card">
                    <div class="profile-avatar-lg"><c:out value="${userInitials}" /></div>
                    <h2 class="profile-name"><c:out value="${sessionScope.username}" /></h2>
                    <p class="profile-email"><c:out value="${sessionScope.email}" /></p>

                    <div class="profile-divider"></div>

                    <div class="profile-stat-row">
                        <span class="profile-stat-label">Total Records</span>
                        <span class="profile-stat-value"><c:out value="${fn:length(filteredExpenses)}" /></span>
                    </div>
                    <div class="profile-stat-row">
                        <span class="profile-stat-label">Total Spent</span>
                        <span class="profile-stat-value">₹<fmt:formatNumber value="${totalFiltered}" pattern="#,##,##0.00"/></span>
                    </div>
                    <div class="profile-stat-row">
                        <span class="profile-stat-label">Top Category</span>
                        <span class="profile-stat-value">
                            <c:choose>
                                <c:when test="${topCategory == '—'}">—</c:when>
                                <c:otherwise><span class="profile-pill"><c:out value="${topCategory}"/></span></c:otherwise>
                            </c:choose>
                        </span>
                    </div>
                </div>

                <!-- Filters Card -->
                <div class="profile-card profile-filters-card">
                    <h2 class="profile-card-title">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="color:var(--primary-color);"><polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/></svg>
                        Filters
                    </h2>
                    <div class="profile-divider"></div>

                    <form id="profileFilterForm" action="${pageContext.request.contextPath}/profile" method="GET" class="profile-filter-form">
                        <div class="profile-field">
                            <label for="f-year">Year</label>
                            <select id="f-year" name="year" class="profile-select">
                                <option value="">All Years</option>
                                <c:forEach var="yr" items="${allYears}">
                                    <option value="${yr}" <c:if test="${filterYear == yr}">selected</c:if>><c:out value="${yr}"/></option>
                                </c:forEach>
                            </select>
                        </div>
                        <div class="profile-field">
                            <label for="f-month">Month</label>
                            <select id="f-month" name="month" class="profile-select">
                                <option value="">All Months</option>
                                <option value="1"  <c:if test="${filterMonth == '1'}">selected</c:if>>January</option>
                                <option value="2"  <c:if test="${filterMonth == '2'}">selected</c:if>>February</option>
                                <option value="3"  <c:if test="${filterMonth == '3'}">selected</c:if>>March</option>
                                <option value="4"  <c:if test="${filterMonth == '4'}">selected</c:if>>April</option>
                                <option value="5"  <c:if test="${filterMonth == '5'}">selected</c:if>>May</option>
                                <option value="6"  <c:if test="${filterMonth == '6'}">selected</c:if>>June</option>
                                <option value="7"  <c:if test="${filterMonth == '7'}">selected</c:if>>July</option>
                                <option value="8"  <c:if test="${filterMonth == '8'}">selected</c:if>>August</option>
                                <option value="9"  <c:if test="${filterMonth == '9'}">selected</c:if>>September</option>
                                <option value="10" <c:if test="${filterMonth == '10'}">selected</c:if>>October</option>
                                <option value="11" <c:if test="${filterMonth == '11'}">selected</c:if>>November</option>
                                <option value="12" <c:if test="${filterMonth == '12'}">selected</c:if>>December</option>
                            </select>
                        </div>
                        <div class="profile-field">
                            <label for="f-day">Day</label>
                            <select id="f-day" name="day" class="profile-select">
                                <option value="">All Days</option>
                                <c:forEach var="d" begin="1" end="31">
                                    <option value="${d}" <c:if test="${filterDay == d}">selected</c:if>><c:out value="${d}"/></option>
                                </c:forEach>
                            </select>
                        </div>
                        <div class="profile-field">
                            <label for="f-cat">Category</label>
                            <select id="f-cat" name="category" class="profile-select">
                                <option value="">All Categories</option>
                                <c:forEach var="cat" items="${allCategories}">
                                    <option value="${cat}" <c:if test="${filterCategory == cat}">selected</c:if>><c:out value="${cat}"/></option>
                                </c:forEach>
                            </select>
                        </div>

                        <div class="profile-filter-actions">
                            <button type="submit" class="profile-btn profile-btn-primary">Apply</button>
                            <a href="${pageContext.request.contextPath}/profile" class="profile-btn profile-btn-reset">Reset</a>
                        </div>
                    </form>
                </div>

            </aside>

            <!-- ================= RIGHT MAIN AREA ================= -->
            <section class="profile-main">

                <!-- Charts Panel -->
                <div class="profile-card profile-charts-panel">
                    <h2 class="profile-card-title">Spending Overview</h2>
                    <div class="profile-divider"></div>
                    <div class="profile-charts-grid">

                        <!-- Doughnut: by category -->
                        <div class="profile-chart-card">
                            <h3 class="profile-chart-title">By Category</h3>
                            <c:choose>
                                <c:when test="${fn:length(categoryData) == 0}">
                                    <div class="profile-chart-empty">
                                        <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M21.21 15.89A10 10 0 1 1 8 2.83"/><path d="M22 12A10 10 0 0 0 12 2v10z"/></svg>
                                        <span>No data for selected filters</span>
                                    </div>
                                </c:when>
                                <c:otherwise>
                                    <div class="profile-chart-wrap">
                                        <canvas id="pieChart"></canvas>
                                    </div>
                                </c:otherwise>
                            </c:choose>
                        </div>

                        <!-- Bar: by month or by day -->
                        <div class="profile-chart-card">
                            <h3 class="profile-chart-title"><c:out value="${barTitle}"/></h3>
                            <div class="profile-chart-wrap" id="barWrap">
                                <canvas id="barChart"></canvas>
                            </div>
                            <div class="profile-chart-empty" id="barEmpty" style="display:none;">
                                <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M21.21 15.89A10 10 0 1 1 8 2.83"/><path d="M22 12A10 10 0 0 0 12 2v10z"/></svg>
                                <span>No data for selected filters</span>
                            </div>
                        </div>

                    </div>
                </div>

                <!-- Filtered Expenses Table -->
                <div class="profile-card profile-table-card">
                    <div class="profile-table-head">
                        <h2 class="profile-card-title">Expenses</h2>
                        <span class="profile-record-count">
                            <c:out value="${fn:length(filteredExpenses)}"/> record(s)
                        </span>
                    </div>
                    <div class="profile-divider"></div>

                    <c:choose>
                        <c:when test="${not empty filteredExpenses}">
                            <div class="profile-table-scroll">
                                <table class="profile-table" id="profileTable">
                                    <thead>
                                        <tr>
                                            <th onclick="sortTable(0)">Date &#9650;&#9660;</th>
                                            <th onclick="sortTable(1)">Title &#9650;&#9660;</th>
                                            <th onclick="sortTable(2)">Category &#9650;&#9660;</th>
                                            <th class="amount-col" onclick="sortTable(3)">Amount (&#8377;) &#9650;&#9660;</th>
                                        </tr>
                                    </thead>
                                    <tbody id="profileTableBody">
                                        <c:forEach var="exp" items="${filteredExpenses}">
                                            <tr>
                                                <td><fmt:formatDate value="${exp.expenseDate}" pattern="yyyy-MM-dd"/></td>
                                                <td><c:out value="${exp.title}"/></td>
                                                <td><span class="profile-pill"><c:out value="${exp.category}"/></span></td>
                                                <td class="amount-col">&#8377;<fmt:formatNumber value="${exp.amount}" pattern="#,##,##0.00"/></td>
                                            </tr>
                                        </c:forEach>
                                    </tbody>
                                    <tfoot>
                                        <tr class="profile-table-total">
                                            <td colspan="3"><strong>Total</strong></td>
                                            <td class="amount-col"><strong>&#8377;<fmt:formatNumber value="${totalFiltered}" pattern="#,##,##0.00"/></strong></td>
                                        </tr>
                                    </tfoot>
                                </table>
                            </div>
                            <div class="pagination" id="pagination"></div>
                        </c:when>
                        <c:otherwise>
                            <div class="profile-table-empty">
                                <svg width="44" height="44" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                                <p>No expenses match your filters</p>
                            </div>
                        </c:otherwise>
                    </c:choose>
                </div>

            </section>
        </div>
    </main>

    <!-- Chart data injected from servlet as JSON -->
    <script type="application/json" id="catLabelsJson">${catLabelsJson}</script>
    <script type="application/json" id="catValuesJson">${catValuesJson}</script>
    <script type="application/json" id="barLabelsJson">${barLabelsJson}</script>
    <script type="application/json" id="barValuesJson">${barValuesJson}</script>

    <script>
    // ================================================================
    // Chart data
    // ================================================================
    function jsonEl(id) {
        return JSON.parse(document.getElementById(id).textContent);
    }
    var catLabels = jsonEl("catLabelsJson");
    var catValues = jsonEl("catValuesJson");
    var barLabels = jsonEl("barLabelsJson");
    var barValues = jsonEl("barValuesJson");

    var BADGE_COLORS = {
        "Food":          "#ef4444",
        "Transport":     "#0ea5e9",
        "Housing":       "#f59e0b",
        "Utilities":     "#3b82f6",
        "Entertainment": "#a855f7",
        "Healthcare":    "#22c55e",
        "Shopping":      "#ec4899",
        "Education":     "#8b5cf6",
        "Other":         "#94a3b8"
    };

    var PIE_PALETTE = [
        "#2563eb","#0ea5e9","#f59e0b","#22c55e","#a855f7",
        "#ec4899","#8b5cf6","#f97316","#14b8a6","#64748b"
    ];

    var TOOLTIP_INR = function(ctx) {
        return " ₹" + parseFloat(ctx.parsed.y !== undefined ? ctx.parsed.y : ctx.parsed).toFixed(2);
    };

    // ---- Doughnut chart (by category) ----
    var pieCtx = document.getElementById("pieChart");
    if (pieCtx && catLabels.length > 0) {
        var pieColors = catLabels.map(function(l, i) {
            return BADGE_COLORS[l] || PIE_PALETTE[i % PIE_PALETTE.length];
        });
        new Chart(pieCtx.getContext("2d"), {
            type: "doughnut",
            data: {
                labels: catLabels,
                datasets: [{
                    data: catValues,
                    backgroundColor: pieColors,
                    borderWidth: 2,
                    borderColor: "#fff"
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                cutout: "60%",
                plugins: {
                    legend: { position: "bottom", labels: { font: { size: 12 }, padding: 14 } },
                    tooltip: { callbacks: { label: TOOLTIP_INR } }
                }
            }
        });
    }

    // ---- Bar chart (by month or by day) ----
    var barCtx = document.getElementById("barChart");
    var barWrap = document.getElementById("barWrap");
    var barEmpty = document.getElementById("barEmpty");
    var hasBarData = barValues.some(function(v) { return parseFloat(v) > 0; });
    if (!hasBarData && barWrap && barEmpty) {
        barWrap.style.display = "none";
        barEmpty.style.display = "flex";
    }
    if (barCtx && hasBarData) {
        new Chart(barCtx.getContext("2d"), {
            type: "bar",
            data: {
                labels: barLabels,
                datasets: [{
                    label: "Spending (₹)",
                    data: barValues,
                    backgroundColor: "rgba(37,99,235,0.75)",
                    hoverBackgroundColor: "#2563eb",
                    borderRadius: 6,
                    maxBarThickness: 42
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false },
                    tooltip: { callbacks: { label: TOOLTIP_INR } }
                },
                scales: {
                    x: { grid: { display: false } },
                    y: {
                        beginAtZero: true,
                        grid: { color: "#f1f5f9" },
                        ticks: { callback: function(v) { return "₹" + v; } }
                    }
                }
            }
        });
    }

    // ================================================================
    // Table client-side sort
    // ================================================================
    var sortAsc = [true, true, true, true];
    function sortTable(colIndex) {
        var tbody = document.getElementById("profileTableBody");
        if (!tbody) return;
        var rows = Array.from(tbody.querySelectorAll("tr"));
        var asc = sortAsc[colIndex];
        rows.sort(function(a, b) {
            var aVal = a.cells[colIndex].textContent.trim().replace(/[₹,]/g, "");
            var bVal = b.cells[colIndex].textContent.trim().replace(/[₹,]/g, "");
            var aNum = parseFloat(aVal), bNum = parseFloat(bVal);
            var cmp;
            if (!isNaN(aNum) && !isNaN(bNum)) {
                cmp = aNum - bNum;
            } else {
                cmp = aVal.localeCompare(bVal);
            }
            return asc ? cmp : -cmp;
        });
        rows.forEach(function(r) { tbody.appendChild(r); });
        sortAsc[colIndex] = !asc;
        currentPage = 1;
        renderPage();
    }

    // ================================================================
    // Pagination (10 rows per page)
    // ================================================================
    var PAGE_SIZE = 10;
    var currentPage = 1;

    function renderPage() {
        var tbody = document.getElementById("profileTableBody");
        var pag   = document.getElementById("pagination");
        if (!tbody || !pag) return;
        var rows = Array.from(tbody.querySelectorAll("tr"));
        var total = rows.length;
        var pages = Math.max(1, Math.ceil(total / PAGE_SIZE));

        rows.forEach(function(r, i) {
            r.style.display = (i >= (currentPage-1)*PAGE_SIZE && i < currentPage*PAGE_SIZE) ? "" : "none";
        });

        pag.innerHTML = "";
        if (pages <= 1) return;

        function mkBtn(label, page, disabled) {
            var b = document.createElement("button");
            b.textContent = label;
            b.className = "page-btn" + (page === currentPage ? " active" : "");
            b.disabled = disabled;
            b.onclick = function() { currentPage = page; renderPage(); };
            return b;
        }
        pag.appendChild(mkBtn("Prev", 1, currentPage === 1));
        pag.appendChild(mkBtn("‹", currentPage-1, currentPage === 1));
        for (var p = Math.max(1, currentPage-2); p <= Math.min(pages, currentPage+2); p++) {
            pag.appendChild(mkBtn(p, p, false));
        }
        pag.appendChild(mkBtn("›", currentPage+1, currentPage === pages));
        pag.appendChild(mkBtn("Next", pages, currentPage === pages));
    }

    document.addEventListener("DOMContentLoaded", function() { renderPage(); });
    </script>
</body>
</html>
