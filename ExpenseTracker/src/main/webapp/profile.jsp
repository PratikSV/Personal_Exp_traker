<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%--
 =====================================================================
 Task 2 – Profile & Analytics View
 Project: Personal Expense Tracker
 =====================================================================
--%>
<%
    if (session.getAttribute("user_id") == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Profile &amp; Analytics - Personal Expense Tracker</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <!-- Chart.js via CDN (no additional JAR needed) -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.3/dist/chart.umd.min.js"></script>
</head>
<body>

    <!-- Navbar (same style as index.jsp) -->
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
            <a href="${pageContext.request.contextPath}/expenses" class="btn-profile">Dashboard</a>
            <form action="${pageContext.request.contextPath}/auth" method="POST" style="display:inline;">
                <input type="hidden" name="action" value="logout">
                <button type="submit" class="btn-logout">Logout</button>
            </form>
        </div>
    </header>

    <main class="container">

        <!-- ============================================================
             User Info Card
             ============================================================ -->
        <div class="profile-info-card">
            <div class="profile-avatar">
                <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/></svg>
            </div>
            <div class="profile-info-text">
                <h2><c:out value="${sessionScope.username}" /></h2>
                <p><c:out value="${sessionScope.email}" /></p>
            </div>
            <div class="profile-stats">
                <div class="profile-stat">
                    <span class="profile-stat-value"><c:out value="${fn:length(filteredExpenses)}" /></span>
                    <span class="profile-stat-label">Records (filtered)</span>
                </div>
                <div class="profile-stat">
                    <span class="profile-stat-value">₹<fmt:formatNumber value="${totalFiltered}" type="number" minFractionDigits="2" maxFractionDigits="2"/></span>
                    <span class="profile-stat-label">Total Spent (filtered)</span>
                </div>
            </div>
        </div>

        <!-- ============================================================
             Filter Panel
             ============================================================ -->
        <div class="card">
            <div class="card-header-flex">
                <h2 class="card-heading">Filters</h2>
            </div>
            <form id="filterForm" action="${pageContext.request.contextPath}/profile" method="GET" class="filter-form">
                <!-- Year -->
                <div class="filter-group">
                    <label for="f-year">Year</label>
                    <select id="f-year" name="year" class="form-control">
                        <option value="">All Years</option>
                        <c:forEach var="yr" items="${allYears}">
                            <option value="${yr}" <c:if test="${filterYear == yr}">selected</c:if>>${yr}</option>
                        </c:forEach>
                    </select>
                </div>
                <!-- Month -->
                <div class="filter-group">
                    <label for="f-month">Month</label>
                    <select id="f-month" name="month" class="form-control">
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
                <!-- Day -->
                <div class="filter-group">
                    <label for="f-day">Day</label>
                    <select id="f-day" name="day" class="form-control">
                        <option value="">All Days</option>
                        <c:forEach var="d" begin="1" end="31">
                            <option value="${d}" <c:if test="${filterDay == d}">selected</c:if>>${d}</option>
                        </c:forEach>
                    </select>
                </div>
                <!-- Category -->
                <div class="filter-group">
                    <label for="f-cat">Category</label>
                    <select id="f-cat" name="category" class="form-control">
                        <option value="">All Categories</option>
                        <c:forEach var="cat" items="${allCategories}">
                            <option value="${cat}" <c:if test="${filterCategory == cat}">selected</c:if>><c:out value="${cat}"/></option>
                        </c:forEach>
                    </select>
                </div>
                <!-- Buttons -->
                <div class="filter-group filter-actions">
                    <button type="submit" class="btn-primary" style="width:auto; padding:0.55rem 1.25rem;">Apply</button>
                    <a href="${pageContext.request.contextPath}/profile" class="btn-modal-cancel" style="text-decoration:none; padding:0.55rem 1.1rem;">Reset</a>
                </div>
            </form>
        </div>

        <!-- ============================================================
             View Toggle (Graph / Table)
             ============================================================ -->
        <div class="view-tabs">
            <button id="tabGraph" class="view-tab active" onclick="switchTab('graph')">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="12" width="4" height="10"/><rect x="9" y="7" width="4" height="15"/><rect x="16" y="2" width="4" height="20"/></svg>
                Graph View
            </button>
            <button id="tabTable" class="view-tab" onclick="switchTab('table')">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2"/><line x1="3" y1="9" x2="21" y2="9"/><line x1="3" y1="15" x2="21" y2="15"/><line x1="9" y1="3" x2="9" y2="21"/></svg>
                Table View
            </button>
        </div>

        <!-- ============================================================
             Graph View
             ============================================================ -->
        <div id="graphView">
            <div class="chart-grid">
                <!-- Doughnut chart: by category -->
                <div class="card chart-card">
                    <div class="card-header-flex">
                        <h2 class="card-heading">Spending by Category</h2>
                    </div>
                    <c:choose>
                        <c:when test="${fn:length(categoryData) == 0}">
                            <div class="empty-state"><p>No data for selected filters.</p></div>
                        </c:when>
                        <c:otherwise>
                            <canvas id="pieChart" height="260"></canvas>
                        </c:otherwise>
                    </c:choose>
                </div>
                <!-- Bar chart: monthly spending -->
                <div class="card chart-card">
                    <div class="card-header-flex">
                        <h2 class="card-heading">Monthly Spending
                            <c:if test="${not empty filterYear}"> – ${filterYear}</c:if>
                        </h2>
                    </div>
                    <canvas id="barChart" height="260"></canvas>
                </div>
            </div>
        </div>

        <!-- ============================================================
             Table View
             ============================================================ -->
        <div id="tableView" style="display:none;">
            <div class="card">
                <div class="card-header-flex">
                    <h2 class="card-heading">Expense Records</h2>
                    <span style="font-size:0.85rem; color:var(--text-muted);">
                        <c:out value="${fn:length(filteredExpenses)}"/> record(s) &nbsp;|&nbsp;
                        Total: ₹<fmt:formatNumber value="${totalFiltered}" type="number" minFractionDigits="2" maxFractionDigits="2"/>
                    </span>
                </div>
                <div class="table-responsive">
                    <c:choose>
                        <c:when test="${not empty filteredExpenses}">
                            <table id="profileTable">
                                <thead>
                                    <tr>
                                        <th onclick="sortTable(0)" style="cursor:pointer;">Date ▲▼</th>
                                        <th onclick="sortTable(1)" style="cursor:pointer;">Category ▲▼</th>
                                        <th onclick="sortTable(2)" style="cursor:pointer;">Title ▲▼</th>
                                        <th class="amount-col" onclick="sortTable(3)" style="cursor:pointer;">Amount (₹) ▲▼</th>
                                    </tr>
                                </thead>
                                <tbody id="profileTableBody">
                                    <c:forEach var="exp" items="${filteredExpenses}">
                                        <tr>
                                            <td><fmt:formatDate value="${exp.expenseDate}" pattern="yyyy-MM-dd"/></td>
                                            <td>
                                                <span class="badge badge-${fn:toLowerCase(exp.category)}">
                                                    <c:out value="${exp.category}"/>
                                                </span>
                                            </td>
                                            <td><c:out value="${exp.title}"/></td>
                                            <td class="amount-col">
                                                ₹<fmt:formatNumber value="${exp.amount}" type="number" minFractionDigits="2" maxFractionDigits="2"/>
                                            </td>
                                        </tr>
                                    </c:forEach>
                                </tbody>
                                <tfoot>
                                    <tr class="table-total-row">
                                        <td colspan="3"><strong>Total</strong></td>
                                        <td class="amount-col">
                                            <strong>₹<fmt:formatNumber value="${totalFiltered}" type="number" minFractionDigits="2" maxFractionDigits="2"/></strong>
                                        </td>
                                    </tr>
                                </tfoot>
                            </table>
                            <!-- Pagination controls -->
                            <div class="pagination" id="pagination"></div>
                        </c:when>
                        <c:otherwise>
                            <div class="empty-state">
                                <p>No expenses match the selected filters.</p>
                            </div>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>
        </div>

    </main>

    <script>
    // ================================================================
    // Chart data injected from servlet (already JSON-safe strings)
    // ================================================================
    var catLabels  = ${catLabelsJson};
    var catValues  = ${catValuesJson};
    var monthVals  = ${monthValuesJson};
    var monthLabels = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];

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
        "#ef4444","#0ea5e9","#f59e0b","#3b82f6","#a855f7",
        "#22c55e","#ec4899","#8b5cf6","#94a3b8","#f97316"
    ];

    // ---- Doughnut chart ----
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
                plugins: {
                    legend: { position: "bottom", labels: { font: { size: 12 }, padding: 16 } },
                    tooltip: {
                        callbacks: {
                            label: function(ctx) {
                                return " ₹" + parseFloat(ctx.parsed).toFixed(2);
                            }
                        }
                    }
                }
            }
        });
    }

    // ---- Bar chart (monthly) ----
    var barCtx = document.getElementById("barChart");
    if (barCtx) {
        new Chart(barCtx.getContext("2d"), {
            type: "bar",
            data: {
                labels: monthLabels,
                datasets: [{
                    label: "Spending (₹)",
                    data: monthVals,
                    backgroundColor: "rgba(37,99,235,0.7)",
                    borderRadius: 4
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        callbacks: {
                            label: function(ctx) {
                                return " ₹" + parseFloat(ctx.parsed.y).toFixed(2);
                            }
                        }
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: {
                            callback: function(v) { return "₹" + v; }
                        }
                    }
                }
            }
        });
    }

    // ================================================================
    // View toggle
    // ================================================================
    function switchTab(tab) {
        var isGraph = (tab === "graph");
        document.getElementById("graphView").style.display = isGraph ? "" : "none";
        document.getElementById("tableView").style.display = isGraph ? "none" : "";
        document.getElementById("tabGraph").classList.toggle("active", isGraph);
        document.getElementById("tabTable").classList.toggle("active", !isGraph);
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
        // Re-paginate after sort
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
        pag.appendChild(mkBtn("«", 1, currentPage === 1));
        pag.appendChild(mkBtn("‹", currentPage-1, currentPage === 1));
        for (var p = Math.max(1, currentPage-2); p <= Math.min(pages, currentPage+2); p++) {
            pag.appendChild(mkBtn(p, p, false));
        }
        pag.appendChild(mkBtn("›", currentPage+1, currentPage === pages));
        pag.appendChild(mkBtn("»", pages, currentPage === pages));
    }

    // Initialise pagination on page load
    document.addEventListener("DOMContentLoaded", function() { renderPage(); });
    </script>
</body>
</html>

