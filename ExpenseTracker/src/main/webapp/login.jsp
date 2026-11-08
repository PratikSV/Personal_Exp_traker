<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%--
 =====================================================================
 Member 5 Deliverable: User Login View
 Project: Personal Expense Tracker
 =====================================================================
--%>
<%
    // Redirect to dashboard if user already has an active authenticated session
    if (session.getAttribute("user_id") != null) {
        response.sendRedirect(request.getContextPath() + "/expenses");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - Personal Expense Tracker</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>
    <div class="auth-wrapper">
        <div class="auth-card">
            <div class="auth-header">
                <h1>ExpenseTracker</h1>
                <p>Sign in to manage and track your finances</p>
            </div>

            <%-- Success Banner (from registration or logout) --%>
            <c:if test="${not empty sessionScope.successMessage}">
                <div class="alert alert-success">
                    <c:out value="${sessionScope.successMessage}" />
                </div>
                <% session.removeAttribute("successMessage"); %>
            </c:if>

            <c:if test="${param.logout == 'true'}">
                <div class="alert alert-success">
                    You have been successfully logged out.
                </div>
            </c:if>

            <%-- Error Banner (from authentication failure) --%>
            <c:if test="${not empty errorMessage}">
                <div class="alert alert-danger">
                    <c:out value="${errorMessage}" />
                </div>
            </c:if>

            <form id="loginForm" action="${pageContext.request.contextPath}/auth" method="POST" novalidate>
                <input type="hidden" name="action" value="login">

                <div class="form-group">
                    <label for="email">Email Address</label>
                    <input type="email" id="email" name="email" class="form-control"
                           value="<c:out value='${email}'/>" placeholder="name@example.com" required autocomplete="email">
                    <span id="emailError" class="form-error"></span>
                </div>

                <div class="form-group">
                    <label for="password">Password</label>
                    <input type="password" id="password" name="password" class="form-control"
                           placeholder="Enter your password" required autocomplete="current-password">
                    <span id="passwordError" class="form-error"></span>
                </div>

                <button type="submit" class="btn-primary" style="margin-top: 0.5rem;">Sign In</button>
            </form>

            <div class="auth-footer">
                Don't have an account?
                <a href="${pageContext.request.contextPath}/register.jsp">Create an Account</a>
            </div>
        </div>
    </div>

    <script src="${pageContext.request.contextPath}/js/validation.js"></script>
</body>
</html>

