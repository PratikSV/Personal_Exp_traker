<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%--
 =====================================================================
 Member 5 Deliverable: User Registration View
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
    <title>Register - Personal Expense Tracker</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>
    <div class="auth-wrapper">
        <div class="auth-card">
            <div class="auth-header">
                <h1>ExpenseTracker</h1>
                <p>Create your personal account</p>
            </div>

            <%-- Error Banner --%>
            <c:if test="${not empty errorMessage}">
                <div class="alert alert-danger">
                    <c:out value="${errorMessage}" />
                </div>
            </c:if>

            <form id="registerForm" action="${pageContext.request.contextPath}/auth" method="POST" novalidate>
                <input type="hidden" name="action" value="register">

                <div class="form-group">
                    <label for="username">Username</label>
                    <input type="text" id="username" name="username" class="form-control"
                           value="<c:out value='${username}'/>" placeholder="e.g. johndoe" required autocomplete="username">
                    <span id="usernameError" class="form-error"></span>
                </div>

                <div class="form-group">
                    <label for="email">Email Address</label>
                    <input type="email" id="email" name="email" class="form-control"
                           value="<c:out value='${email}'/>" placeholder="name@example.com" required autocomplete="email">
                    <span id="emailError" class="form-error"></span>
                </div>

                <div class="form-group">
                    <label for="password">Password (min. 6 characters)</label>
                    <input type="password" id="password" name="password" class="form-control"
                           placeholder="Create a strong password" required autocomplete="new-password">
                    <span id="passwordError" class="form-error"></span>
                </div>

                <div class="form-group">
                    <label for="confirmPassword">Confirm Password</label>
                    <input type="password" id="confirmPassword" name="confirmPassword" class="form-control"
                           placeholder="Confirm your password" required autocomplete="new-password">
                    <span id="confirmPasswordError" class="form-error"></span>
                </div>

                <button type="submit" class="btn-primary" style="margin-top: 0.5rem;">Create Account</button>
            </form>

            <div class="auth-footer">
                Already have an account?
                <a href="${pageContext.request.contextPath}/login.jsp">Sign In</a>
            </div>
        </div>
    </div>

    <script src="${pageContext.request.contextPath}/js/validation.js"></script>
</body>
</html>

