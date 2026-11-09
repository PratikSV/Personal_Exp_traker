<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
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

    <!-- Main Navigation Bar (matches index.jsp layout) -->
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
                Welcome, <strong><c:out value="${profileUser.username != null ? profileUser.username : sessionScope.username}" /></strong>
            </span>
            <a href="${pageContext.request.contextPath}/expenses" class="profile-nav-dashboard">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/></svg>
                Dashboard
            </a>
            <form action="${pageContext.request.contextPath}/auth" method="POST" style="display:inline;">
                <input type="hidden" name="action" value="logout">
                <button type="submit" class="btn-logout">Logout</button>
            </form>
        </div>
    </header>

    <!-- Main Content Container -->
    <main class="container profile-page">
        <div class="profile-layout">

            <!-- LEFT COLUMN (two stacked cards) -->
            <div class="profile-col-left">

                <!-- A) Profile Info Card -->
                <div class="profile-card">
                    <h2 class="profile-card-heading">Profile Info</h2>
                    <div class="profile-user-row">
                        <div class="profile-avatar"><c:out value="${userInitial}" /></div>
                        <div class="profile-user-details">
                            <div class="profile-user-name"><c:out value="${profileUser.username}" /></div>
                            <div class="profile-user-email"><c:out value="${profileUser.email}" /></div>
                        </div>
                    </div>

                    <div class="profile-divider"></div>

                    <div class="profile-stats-list">
                        <div class="profile-stat-item">
                            <div class="profile-stat-icon">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                                    <polyline points="14 2 14 8 20 8"></polyline>
                                    <line x1="16" y1="13" x2="8" y2="13"></line>
                                    <line x1="16" y1="17" x2="8" y2="17"></line>
                                    <polyline points="10 9 9 9 8 9"></polyline>
                                </svg>
                            </div>
                            <span class="profile-stat-text">Total Records: <strong><c:out value="${totalRecords}" /></strong></span>
                        </div>
                        <div class="profile-stat-item">
                            <div class="profile-stat-icon">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <rect x="2" y="6" width="20" height="12" rx="2"></rect>
                                    <circle cx="12" cy="12" r="2"></circle>
                                    <path d="M6 12h.01M18 12h.01"></path>
                                </svg>
                            </div>
                            <span class="profile-stat-text">Total Spent: <strong>₹<fmt:formatNumber value="${totalSpent}" pattern="#,##,##0.00"/></strong></span>
                        </div>
                        <div class="profile-stat-item">
                            <div class="profile-stat-icon">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"></polygon>
                                </svg>
                            </div>
                            <span class="profile-stat-text">Top Category: <strong><c:out value="${topCategory}" /></strong></span>
                        </div>
                    </div>
                </div>

                <!-- B) Filters Card -->
                <div class="profile-card">
                    <h2 class="profile-card-heading">Filters</h2>
                    <form id="profileFilterForm" action="${pageContext.request.contextPath}/profile" method="GET" class="profile-filters-form">
                        <div class="profile-filter-row">
                            <label for="filterYear" class="profile-filter-label">Year</label>
                            <select id="filterYear" name="year" class="profile-filter-select">
                                <option value="">All Years</option>
                                <c:forEach var="yr" items="${allYears}">
                                    <option value="${yr}" <c:if test="${filterYear == yr}">selected</c:if>><c:out value="${yr}"/></option>
                                </c:forEach>
                            </select>
                        </div>
                        <div class="profile-filter-row">
                            <label for="filterMonth" class="profile-filter-label">Month</label>
                            <select id="filterMonth" name="month" class="profile-filter-select">
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
                        <div class="profile-filter-row">
                            <label for="filterDay" class="profile-filter-label">Day</label>
                            <select id="filterDay" name="day" class="profile-filter-select">
                                <option value="">All Days</option>
                                <c:forEach var="d" begin="1" end="31">
                                    <option value="${d}" <c:if test="${filterDay == d}">selected</c:if>><c:out value="${d}"/></option>
                                </c:forEach>
                            </select>
                        </div>
                        <div class="profile-filter-row">
                            <label for="filterCategory" class="profile-filter-label">Category</label>
                            <select id="filterCategory" name="category" class="profile-filter-select">
                                <option value="">All Categories</option>
                                <c:forEach var="cat" items="${allCategories}">
                                    <option value="${cat}" <c:if test="${filterCategory == cat}">selected</c:if>><c:out value="${cat}"/></option>
                                </c:forEach>
                            </select>
                        </div>
                        <div class="profile-filter-actions">
                            <button type="submit" class="profile-btn-apply">Apply</button>
                            <a href="${pageContext.request.contextPath}/profile" class="profile-btn-reset-link">Reset</a>
                        </div>
                    </form>
                </div>

            </div>

            <!-- RIGHT COLUMN (two stacked cards) -->
            <div class="profile-col-right">

                <!-- C) Spending Overview Card -->
                <div class="profile-card">
                    <h2 class="profile-card-heading">Spending Overview</h2>
                    <div class="profile-overview-grid">
                        <!-- By Category -->
                        <div class="profile-chart-col">
                            <h3 class="profile-chart-subtitle">By Category</h3>
                            <div class="profile-chart-container" id="categoryChartContainer">
                                <canvas id="categoryChart"></canvas>
                            </div>
                            <div class="profile-empty-chart" id="categoryEmpty" style="display:none;">
                                No data for selected filters
                            </div>
                        </div>

                        <!-- By Month / By Day -->
                        <div class="profile-chart-col">
                            <h3 class="profile-chart-subtitle" id="barChartTitle"><c:out value="${barTitle}"/></h3>
                            <div class="profile-chart-container" id="barChartContainer">
                                <canvas id="barChart"></canvas>
                            </div>
                            <div class="profile-empty-chart" id="barEmpty" style="display:none;">
                                No data for selected filters
                            </div>
                        </div>
                    </div>
                </div>

                <!-- D) Expenses Card -->
                <div class="profile-card">
                    <h2 class="profile-card-heading">Expenses</h2>
                    <div class="profile-record-subtitle"><c:out value="${totalRecords}" /> record(s)</div>

                    <div class="profile-table-container">
                        <table class="profile-data-table" id="expensesTable">
                            <thead>
                                <tr>
                                    <th onclick="sortTable(0)">Date <span class="profile-sort-arrow">&#9650;&#9660;</span></th>
                                    <th onclick="sortTable(1)">Title <span class="profile-sort-arrow">&#9650;&#9660;</span></th>
                                    <th onclick="sortTable(2)">Category <span class="profile-sort-arrow">&#9650;&#9660;</span></th>
                                    <th class="amount-col" onclick="sortTable(3)">Amount (₹) <span class="profile-sort-arrow">&#9650;&#9660;</span></th>
                                </tr>
                            </thead>
                            <tbody id="expensesTableBody">
                                <c:choose>
                                    <c:when test="${not empty filteredExpenses}">
                                        <c:forEach var="exp" items="${filteredExpenses}">
                                            <tr>
                                                <td><fmt:formatDate value="${exp.expenseDate}" pattern="yyyy-MM-dd"/></td>
                                                <td><c:out value="${exp.title}"/></td>
                                                <td><c:out value="${exp.category}"/></td>
                                                <td class="amount-col">₹<fmt:formatNumber value="${exp.amount}" pattern="#,##,##0.00"/></td>
                                            </tr>
                                        </c:forEach>
                                    </c:when>
                                    <c:otherwise>
                                        <tr class="profile-empty-row">
                                            <td colspan="4">No expenses match your filters</td>
                                        </tr>
                                    </c:otherwise>
                                </c:choose>
                            </tbody>
                            <c:if test="${not empty filteredExpenses}">
                                <tfoot>
                                    <tr class="profile-total-row">
                                        <td colspan="3"><strong>Total</strong></td>
                                        <td class="amount-col"><strong>₹<fmt:formatNumber value="${totalSpent}" pattern="#,##,##0.00"/></strong></td>
                                    </tr>
                                </tfoot>
                            </c:if>
                        </table>
                    </div>
                    <div class="profile-pagination" id="tablePagination"></div>
                </div>

            </div>
        </div>
    </main>

    <!-- Embedded JSON Data from Server -->
    <script type="application/json" id="catLabelsJson">${catLabelsJson}</script>
    <script type="application/json" id="catValuesJson">${catValuesJson}</script>
    <script type="application/json" id="barLabelsJson">${barLabelsJson}</script>
    <script type="application/json" id="barValuesJson">${barValuesJson}</script>

    <script>
    // ================================================================
    // Safe JSON Retrieval
    // ================================================================
    function getJson(id) {
        var el = document.getElementById(id);
        if (!el || !el.textContent.trim()) return [];
        try {
            return JSON.parse(el.textContent);
        } catch (e) {
            console.error("JSON parse error for " + id, e);
            return [];
        }
    }

    var catLabels = getJson("catLabelsJson");
    var catValues = getJson("catValuesJson").map(Number);
    var barLabels = getJson("barLabelsJson");
    var barValues = getJson("barValuesJson").map(Number);

    // Fixed category palette to ensure consistency across the application
    var CATEGORY_COLORS = {
        "Food":          "#ef4444",
        "Transport":     "#3b82f6",
        "Housing":       "#f59e0b",
        "Utilities":     "#6366f1",
        "Entertainment": "#a855f7",
        "Healthcare":    "#22c55e",
        "Shopping":      "#ec4899",
        "Education":     "#8b5cf6",
        "Other":         "#94a3b8"
    };

    var FALLBACK_COLORS = [
        "#ef4444", "#3b82f6", "#22c55e", "#f59e0b", "#a855f7",
        "#ec4899", "#8b5cf6", "#14b8a6", "#f97316", "#64748b"
    ];

    // ================================================================
    // Doughnut Chart: By Category
    // ================================================================
    var catContainer = document.getElementById("categoryChartContainer");
    var catEmpty = document.getElementById("categoryEmpty");
    var hasCatData = catValues.length > 0 && catValues.some(function(v) { return v > 0; });

    if (!hasCatData) {
        if (catContainer) catContainer.style.display = "none";
        if (catEmpty) catEmpty.style.display = "flex";
    } else {
        var doughnutColors = catLabels.map(function(label, index) {
            return CATEGORY_COLORS[label] || FALLBACK_COLORS[index % FALLBACK_COLORS.length];
        });

        var catCanvas = document.getElementById("categoryChart");
        if (catCanvas) {
            new Chart(catCanvas.getContext("2d"), {
                type: "doughnut",
                data: {
                    labels: catLabels,
                    datasets: [{
                        data: catValues,
                        backgroundColor: doughnutColors,
                        borderWidth: 2,
                        borderColor: "#ffffff",
                        hoverOffset: 4
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    cutout: "60%",
                    plugins: {
                        legend: {
                            position: "bottom",
                            labels: {
                                usePointStyle: true,
                                pointStyle: "rect",
                                boxWidth: 10,
                                boxHeight: 10,
                                padding: 14,
                                font: {
                                    size: 12,
                                    family: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
                                },
                                color: "#475569"
                            }
                        },
                        tooltip: {
                            callbacks: {
                                label: function(ctx) {
                                    var val = parseFloat(ctx.parsed !== undefined ? ctx.parsed : ctx.raw).toFixed(2);
                                    return " " + ctx.label + ": ₹" + val;
                                }
                            }
                        }
                    }
                }
            });
        }
    }

    // ================================================================
    // Bar Chart: By Month / By Day
    // ================================================================
    var barContainer = document.getElementById("barChartContainer");
    var barEmpty = document.getElementById("barEmpty");
    var hasBarData = barValues.length > 0 && barValues.some(function(v) { return v > 0; });

    if (!hasBarData) {
        if (barContainer) barContainer.style.display = "none";
        if (barEmpty) barEmpty.style.display = "flex";
    } else {
        var barCanvas = document.getElementById("barChart");
        if (barCanvas) {
            new Chart(barCanvas.getContext("2d"), {
                type: "bar",
                data: {
                    labels: barLabels,
                    datasets: [{
                        data: barValues,
                        backgroundColor: "#3b82f6",
                        hoverBackgroundColor: "#2563eb",
                        borderRadius: { topLeft: 4, topRight: 4 },
                        maxBarThickness: 36
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: false },
                        tooltip: {
                            callbacks: {
                                label: function(ctx) {
                                    var val = parseFloat(ctx.parsed.y).toFixed(2);
                                    return " Spending: ₹" + val;
                                }
                            }
                        }
                    },
                    scales: {
                        x: {
                            grid: { display: false },
                            ticks: {
                                color: "#64748b",
                                font: { size: 12 }
                            }
                        },
                        y: {
                            beginAtZero: true,
                            grid: {
                                color: "#f1f5f9"
                            },
                            ticks: {
                                color: "#64748b",
                                font: { size: 12 },
                                callback: function(val) {
                                    return "₹" + val;
                                }
                            }
                        }
                    }
                }
            });
        }
    }

    // ================================================================
    // Table Sorting (Client-side)
    // ================================================================
    // Initial order is date descending (col 0 desc)
    var sortAscState = [false, true, true, false];

    function sortTable(colIndex) {
        var tbody = document.getElementById("expensesTableBody");
        if (!tbody) return;
        var rows = Array.from(tbody.querySelectorAll("tr"));
        // Skip sorting if there is only the empty row
        if (rows.length === 1 && rows[0].classList.contains("profile-empty-row")) return;

        var isAsc = sortAscState[colIndex];

        rows.sort(function(rowA, rowB) {
            var cellA = rowA.cells[colIndex].textContent.trim();
            var cellB = rowB.cells[colIndex].textContent.trim();

            if (colIndex === 3) {
                // Numeric amount sort
                var numA = parseFloat(cellA.replace(/[₹,]/g, "")) || 0;
                var numB = parseFloat(cellB.replace(/[₹,]/g, "")) || 0;
                return isAsc ? numA - numB : numB - numA;
            } else if (colIndex === 0) {
                // Date sort (yyyy-MM-dd formatted string)
                return isAsc ? cellA.localeCompare(cellB) : cellB.localeCompare(cellA);
            } else {
                // Text sort
                return isAsc ? cellA.localeCompare(cellB) : cellB.localeCompare(cellA);
            }
        });

        rows.forEach(function(r) { tbody.appendChild(r); });
        sortAscState[colIndex] = !isAsc;

        currentTablePage = 1;
        renderPagination();
    }

    // ================================================================
    // Table Pagination (10 rows per page)
    // ================================================================
    var ROWS_PER_PAGE = 10;
    var currentTablePage = 1;

    function renderPagination() {
        var tbody = document.getElementById("expensesTableBody");
        var pagContainer = document.getElementById("tablePagination");
        if (!tbody || !pagContainer) return;

        var rows = Array.from(tbody.querySelectorAll("tr"));
        if (rows.length === 1 && rows[0].classList.contains("profile-empty-row")) {
            pagContainer.innerHTML = "";
            return;
        }

        var totalRows = rows.length;
        var totalPages = Math.ceil(totalRows / ROWS_PER_PAGE);

        rows.forEach(function(row, idx) {
            var start = (currentTablePage - 1) * ROWS_PER_PAGE;
            var end = start + ROWS_PER_PAGE;
            row.style.display = (idx >= start && idx < end) ? "" : "none";
        });

        pagContainer.innerHTML = "";
        if (totalPages <= 1) return;

        function createPageBtn(label, targetPage, disabled, isActive) {
            var btn = document.createElement("button");
            btn.type = "button";
            btn.textContent = label;
            btn.className = "page-btn" + (isActive ? " active" : "");
            btn.disabled = disabled;
            btn.onclick = function() {
                currentTablePage = targetPage;
                renderPagination();
            };
            return btn;
        }

        pagContainer.appendChild(createPageBtn("Prev", currentTablePage - 1, currentTablePage === 1, false));

        for (var p = 1; p <= totalPages; p++) {
            pagContainer.appendChild(createPageBtn(p, p, false, p === currentTablePage));
        }

        pagContainer.appendChild(createPageBtn("Next", currentTablePage + 1, currentTablePage === totalPages, false));
    }

    document.addEventListener("DOMContentLoaded", function() {
        renderPagination();
    });
    </script>
</body>
</html>
