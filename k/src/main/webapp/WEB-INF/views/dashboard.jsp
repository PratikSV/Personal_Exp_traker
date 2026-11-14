<%@ page contentType="text/html;charset=UTF-8" %><%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Dashboard · Pennywise</title>
    <link rel="stylesheet" href="${ctx}/assets/css/app.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
<%@ include file="nav.jspf" %>
<main class="main">
    <div class="page-head">
        <div>
            <p class="eyebrow">FINANCIAL OVERVIEW</p>
            <h1>Good day, <c:out value="${name}"/>.</h1>
            <p class="muted">
                <c:choose>
                    <c:when test="${isFiltered}">Showing filtered results based on your selected criteria.</c:when>
                    <c:otherwise>Here's your comprehensive financial snapshot and cash flow overview.</c:otherwise>
                </c:choose>
            </p>
        </div>
        <div class="page-head-actions">
            <a class="btn primary" href="${ctx}/transactions">＋ Add transaction</a>
            <button type="button" class="btn ${isFiltered ? 'primary' : 'ghost'} filter-toggle-btn" id="toggleFilterBtn" onclick="toggleFilterPanel()" title="Toggle filter form">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" style="margin-right:6px">
                    <polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"></polygon>
                </svg>
                Filter<c:if test="${isFiltered}"> <span class="filter-count-badge">●</span></c:if>
            </button>
        </div>
    </div>

    <!-- Filter Section (Hidden by default; toggled via Filter button) -->
    <section class="panel filter-panel" id="filterPanel" style="${isFiltered ? 'display: block;' : 'display: none;'}">
        <div class="filter-head">
            <div>
                <h2>Filter Analytics &amp; Reports</h2>
                <p class="muted">Filter cash flow line chart, spending breakdown, summary totals, and recent activity by date range, type, or category.</p>
            </div>
            <c:if test="${isFiltered}">
                <span class="pill filter-active-pill">● Filter Active</span>
            </c:if>
        </div>
        <form id="filterForm" method="get" action="${ctx}/dashboard" class="filter-form">
            <div class="filter-field">
                <label for="startDate">From Date</label>
                <input type="date" id="startDate" name="startDate" value="<c:out value='${filterStartDate}'/>">
            </div>
            <div class="filter-field">
                <label for="endDate">To Date</label>
                <input type="date" id="endDate" name="endDate" value="<c:out value='${filterEndDate}'/>">
            </div>
            <div class="filter-field">
                <label for="type">Transaction Type</label>
                <select id="type" name="type">
                    <option value="ALL" ${filterType == 'ALL' ? 'selected' : ''}>All (Income &amp; Expenses)</option>
                    <option value="EXPENSE" ${filterType == 'EXPENSE' ? 'selected' : ''}>Expenses Only</option>
                    <option value="INCOME" ${filterType == 'INCOME' ? 'selected' : ''}>Income Only</option>
                </select>
            </div>
            <div class="filter-field">
                <label for="categoryId">Category</label>
                <select id="categoryId" name="categoryId">
                    <option value="">All Categories</option>
                    <c:forEach items="${allCategories}" var="c">
                        <option value="${c.category_id}" ${filterCategoryId == c.category_id ? 'selected' : ''}>
                            <c:out value="${c.category_name}"/> (<c:out value="${c.category_type}"/>)
                        </option>
                    </c:forEach>
                </select>
            </div>
            <div class="filter-actions">
                <button type="submit" class="btn primary">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="margin-right:6px"><polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/></svg>
                    Apply Filter
                </button>
                <a href="${ctx}/dashboard" class="btn ghost">Reset</a>
            </div>
        </form>
        <div class="preset-bar">
            <span class="preset-label">Quick Presets:</span>
            <button type="button" class="preset-btn" onclick="applyPreset('today')">Today</button>
            <button type="button" class="preset-btn" onclick="applyPreset('thisMonth')">This Month</button>
            <button type="button" class="preset-btn" onclick="applyPreset('last30')">Last 30 Days</button>
            <button type="button" class="preset-btn" onclick="applyPreset('last3m')">Last 3 Months</button>
            <button type="button" class="preset-btn" onclick="applyPreset('last6m')">Last 6 Months</button>
            <button type="button" class="preset-btn" onclick="applyPreset('thisYear')">This Year</button>
            <button type="button" class="preset-btn" onclick="applyPreset('all')">All Time</button>
        </div>
    </section>

    <!-- Financial Stats Summary (Always shows overall totals) -->
    <section class="stats">
        <article class="stat balance">
            <span>Total balance</span>
            <strong>₹ <c:out value="${balance}"/></strong>
            <small>Income minus expenses</small>
        </article>
        <!-- Total Income & Total Expenses side by side in the same box -->
        <article class="stat stat-split-box">
            <div class="stat-half">
                <span>Total income</span>
                <strong class="green">+ ₹ <c:out value="${income}"/></strong>
                <small>All recorded income</small>
            </div>
            <div class="stat-divider"></div>
            <div class="stat-half">
                <span>Total expenses</span>
                <strong class="red">− ₹ <c:out value="${expense}"/></strong>
                <small>All recorded spending</small>
            </div>
        </article>
    </section>

    <!-- Charts Grid: Line Graph & Pie Chart -->
    <section class="chart-grid">
        <!-- 1. Cash Flow Line Graph -->
        <article class="panel">
            <div class="panel-head">
                <div>
                    <h2>Cash Flow Trend</h2>
                    <p class="muted">Income vs Expenses timeline · Line Graph</p>
                </div>
                <span class="chart-meta-pill">Line Graph</span>
            </div>
            <div class="chart-wrap">
                <canvas id="flowChart"></canvas>
            </div>
            <!-- Data Breakdown for Line Chart -->
            <div class="chart-data-section">
                <div class="data-section-title">
                    <strong>Cash Flow Data Breakdown</strong>
                    <small class="muted">Timeline metrics</small>
                </div>
                <div class="table-scroll chart-table-wrap">
                    <table>
                        <thead>
                            <tr>
                                <th>Period</th>
                                <th class="right">Income</th>
                                <th class="right">Expenses</th>
                                <th class="right">Net Cash Flow</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:forEach items="${monthly}" var="m">
                                <c:set var="mNet" value="${(m.income_total != null ? m.income_total : 0) - (m.expense_total != null ? m.expense_total : 0)}"/>
                                <tr>
                                    <td><strong><c:out value="${m.period_label}"/></strong></td>
                                    <td class="right green">+ ₹ <c:out value="${m.income_total != null ? m.income_total : 0}"/></td>
                                    <td class="right red">− ₹ <c:out value="${m.expense_total != null ? m.expense_total : 0}"/></td>
                                    <td class="right ${mNet >= 0 ? 'green' : 'red'}">
                                        ${mNet >= 0 ? '+' : '−'} ₹ <c:out value="${mNet >= 0 ? mNet : -mNet}"/>
                                    </td>
                                </tr>
                            </c:forEach>
                            <c:if test="${empty monthly}">
                                <tr>
                                    <td colspan="4" class="empty">No cash flow timeline data for the selected range.</td>
                                </tr>
                            </c:if>
                        </tbody>
                    </table>
                </div>
            </div>
        </article>

        <!-- 2. Spending Breakdown Pie Chart -->
        <article class="panel">
            <div class="panel-head">
                <div>
                    <h2><c:out value="${filterType == 'INCOME' ? 'Income Breakdown' : 'Spending Breakdown'}"/></h2>
                    <p class="muted">Distribution by category · Pie Chart</p>
                </div>
                <span class="chart-meta-pill">Pie Chart</span>
            </div>
            <div class="chart-wrap pie-wrap">
                <canvas id="categoryChart"></canvas>
            </div>
            <!-- Data Breakdown for Pie Chart -->
            <div class="chart-data-section">
                <div class="data-section-title">
                    <strong>Category Data Breakdown</strong>
                    <small class="muted">Amounts and % share</small>
                </div>
                <div class="cat-breakdown-list">
                    <c:forEach items="${categories}" var="c" varStatus="st">
                        <div class="cat-item">
                            <div class="cat-left">
                                <span class="cat-color-dot" id="dot-${st.index}"></span>
                                <span class="cat-name"><c:out value="${c.category_name}"/></span>
                            </div>
                            <div class="cat-right">
                                <span class="cat-pct" id="pct-${st.index}">-</span>
                                <strong class="cat-amt">₹ <c:out value="${c.total}"/></strong>
                            </div>
                        </div>
                    </c:forEach>
                    <c:if test="${empty categories}">
                        <p class="empty" style="padding:16px;text-align:center">No breakdown data available for this selection.</p>
                    </c:if>
                </div>
            </div>
        </article>
    </section>

    <!-- Recent Activity Table -->
    <section class="panel">
        <div class="panel-head">
            <div>
                <h2>Recent activity</h2>
                <p class="muted">
                    <c:choose>
                        <c:when test="${isFiltered}">Filtered transactions matching your criteria</c:when>
                        <c:otherwise>Your latest recorded transactions</c:otherwise>
                    </c:choose>
                </p>
            </div>
            <a href="${ctx}/transactions">View all transactions →</a>
        </div>
        <div class="table-scroll">
            <table>
                <thead>
                    <tr>
                        <th>Description</th>
                        <th>Type</th>
                        <th>Date</th>
                        <th class="right">Amount</th>
                    </tr>
                </thead>
                <tbody>
                    <c:forEach items="${recent}" var="t">
                        <tr>
                            <td><strong><c:out value="${t.title}"/></strong></td>
                            <td>
                                <span class="pill ${t.kind == 'Income' ? 'pill-green' : 'pill-red'}">
                                    <c:out value="${t.kind}"/>
                                </span>
                            </td>
                            <td><c:out value="${t.tx_date}"/></td>
                            <td class="right ${t.kind == 'Income' ? 'green' : 'red'}">
                                ${t.kind == 'Income' ? '+ ' : '− '}₹ <c:out value="${t.amount}"/>
                            </td>
                        </tr>
                    </c:forEach>
                    <c:if test="${empty recent}">
                        <tr>
                            <td colspan="4" class="empty">No transactions found matching the filter criteria.</td>
                        </tr>
                    </c:if>
                </tbody>
            </table>
        </div>
    </section>
</main>

<script>
// Distinct color palette for charts
const chartColors = [
    '#496fd8', '#27ae83', '#f1b95b', '#e77e70', '#8b79d6', 
    '#5aabc0', '#b2c66b', '#d38da9', '#8a9aab', '#e0a15b',
    '#2563eb', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6'
];

// Data from controller
const months = [
<c:forEach items="${monthly}" var="x" varStatus="s">
    <c:if test="${!s.first}">,</c:if>"<c:out value='${x.period_label}'/>"
</c:forEach>
];

const ins = [
<c:forEach items="${monthly}" var="x" varStatus="s">
    <c:if test="${!s.first}">,</c:if><c:out value="${x.income_total != null ? x.income_total : 0}"/>
</c:forEach>
];

const outs = [
<c:forEach items="${monthly}" var="x" varStatus="s">
    <c:if test="${!s.first}">,</c:if><c:out value="${x.expense_total != null ? x.expense_total : 0}"/>
</c:forEach>
];

const cats = [
<c:forEach items="${categories}" var="x" varStatus="s">
    <c:if test="${!s.first}">,</c:if>"<c:out value='${x.category_name}'/>"
</c:forEach>
];

const vals = [
<c:forEach items="${categories}" var="x" varStatus="s">
    <c:if test="${!s.first}">,</c:if><c:out value="${x.total != null ? x.total : 0}"/>
</c:forEach>
];

// Set category colors and percentage badges
const totalCategorySum = vals.reduce((acc, curr) => acc + curr, 0);
cats.forEach((_, idx) => {
    const dot = document.getElementById('dot-' + idx);
    if (dot) dot.style.backgroundColor = chartColors[idx % chartColors.length];
    
    const pctEl = document.getElementById('pct-' + idx);
    if (pctEl) {
        const pct = totalCategorySum > 0 ? ((vals[idx] / totalCategorySum) * 100).toFixed(1) : 0;
        pctEl.textContent = pct + '%';
    }
});

// 1. CASH FLOW LINE GRAPH
const flowCanvas = document.getElementById('flowChart');
if (flowCanvas) {
    const filterType = "${filterType}";
    const isIncomeOnly = filterType === "INCOME";
    const isExpenseOnly = filterType === "EXPENSE";

    const flowDatasets = [];
    if (!isExpenseOnly) {
        flowDatasets.push({
            label: 'Income',
            data: ins,
            borderColor: '#27ae83',
            backgroundColor: 'rgba(39, 174, 131, 0.12)',
            borderWidth: 3,
            tension: 0.35,
            fill: true,
            pointRadius: 5,
            pointHoverRadius: 8,
            pointBackgroundColor: '#27ae83',
            pointBorderColor: '#ffffff',
            pointBorderWidth: 2
        });
    }
    if (!isIncomeOnly) {
        flowDatasets.push({
            label: 'Expenses',
            data: outs,
            borderColor: '#f07868',
            backgroundColor: 'rgba(240, 120, 104, 0.12)',
            borderWidth: 3,
            tension: 0.35,
            fill: true,
            pointRadius: 5,
            pointHoverRadius: 8,
            pointBackgroundColor: '#f07868',
            pointBorderColor: '#ffffff',
            pointBorderWidth: 2
        });
    }

    new Chart(flowCanvas, {
        type: 'line',
        data: {
            labels: months.length > 0 ? months : ['No Data'],
            datasets: flowDatasets.length > 0 ? flowDatasets : [{
                label: 'No Activity',
                data: [0],
                borderColor: '#cbd5e1',
                borderDash: [5, 5]
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            interaction: {
                mode: 'index',
                intersect: false
            },
            plugins: {
                legend: {
                    position: 'top',
                    labels: {
                        usePointStyle: true,
                        boxWidth: 8,
                        font: { family: 'DM Sans', size: 12, weight: '600' }
                    }
                },
                tooltip: {
                    backgroundColor: 'rgba(32, 40, 59, 0.95)',
                    padding: 12,
                    cornerRadius: 8,
                    callbacks: {
                        label: function(ctx) {
                            return ' ' + ctx.dataset.label + ': ₹ ' + Number(ctx.raw).toLocaleString('en-IN', {minimumFractionDigits: 2});
                        }
                    }
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    grid: { color: '#f1f5f9' },
                    ticks: {
                        font: { family: 'DM Sans', size: 11 },
                        callback: function(v) { return '₹ ' + Number(v).toLocaleString('en-IN'); }
                    }
                },
                x: {
                    grid: { display: false },
                    ticks: {
                        font: { family: 'DM Sans', size: 11, weight: '500' }
                    }
                }
            }
        }
    });
}

// 2. SPENDING BREAKDOWN PIE CHART
const categoryCanvas = document.getElementById('categoryChart');
if (categoryCanvas) {
    const hasCategoryData = vals.length > 0 && totalCategorySum > 0;

    new Chart(categoryCanvas, {
        type: 'pie',
        data: {
            labels: hasCategoryData ? cats : ['No Data Recorded'],
            datasets: [{
                data: hasCategoryData ? vals : [1],
                backgroundColor: hasCategoryData ? chartColors.slice(0, cats.length) : ['#e2e8f0'],
                borderWidth: 2,
                borderColor: '#ffffff'
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: {
                        usePointStyle: true,
                        boxWidth: 8,
                        font: { family: 'DM Sans', size: 11 },
                        padding: 10
                    }
                },
                tooltip: {
                    backgroundColor: 'rgba(32, 40, 59, 0.95)',
                    padding: 12,
                    cornerRadius: 8,
                    callbacks: {
                        label: function(ctx) {
                            if (!hasCategoryData) return ' No transactions recorded';
                            const val = ctx.raw;
                            const pct = totalCategorySum > 0 ? ((val / totalCategorySum) * 100).toFixed(1) : 0;
                            return ' ' + ctx.label + ': ₹ ' + Number(val).toLocaleString('en-IN', {minimumFractionDigits: 2}) + ' (' + pct + '%)';
                        }
                    }
                }
            }
        }
    });
}

// 3. TOGGLE FILTER PANEL VISIBILITY
function toggleFilterPanel() {
    const panel = document.getElementById('filterPanel');
    if (!panel) return;
    if (panel.style.display === 'none' || panel.style.display === '') {
        panel.style.display = 'block';
        panel.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    } else {
        panel.style.display = 'none';
    }
}

// 4. QUICK PRESET HELPER
function applyPreset(preset) {
    const startInput = document.getElementById('startDate');
    const endInput = document.getElementById('endDate');
    const form = document.getElementById('filterForm');
    const now = new Date();

    function formatYMD(d) {
        const y = d.getFullYear();
        const m = String(d.getMonth() + 1).padStart(2, '0');
        const day = String(d.getDate()).padStart(2, '0');
        return y + '-' + m + '-' + day;
    }

    if (preset === 'today') {
        startInput.value = formatYMD(now);
        endInput.value = formatYMD(now);
    } else if (preset === 'thisMonth') {
        const first = new Date(now.getFullYear(), now.getMonth(), 1);
        startInput.value = formatYMD(first);
        endInput.value = formatYMD(now);
    } else if (preset === 'last30') {
        const past = new Date();
        past.setDate(now.getDate() - 30);
        startInput.value = formatYMD(past);
        endInput.value = formatYMD(now);
    } else if (preset === 'last3m') {
        const past = new Date();
        past.setMonth(now.getMonth() - 3);
        startInput.value = formatYMD(past);
        endInput.value = formatYMD(now);
    } else if (preset === 'last6m') {
        const past = new Date();
        past.setMonth(now.getMonth() - 6);
        startInput.value = formatYMD(past);
        endInput.value = formatYMD(now);
    } else if (preset === 'thisYear') {
        const first = new Date(now.getFullYear(), 0, 1);
        startInput.value = formatYMD(first);
        endInput.value = formatYMD(now);
    } else if (preset === 'all') {
        startInput.value = '';
        endInput.value = '';
    }
    form.submit();
}
</script>
</body>
</html>
