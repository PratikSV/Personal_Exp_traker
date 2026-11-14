<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <title>Create account · Pennywise</title>
        <link rel="stylesheet" href="${ctx}/assets/css/app.css">
    </head>
    <body class="auth-body">
        <main class="auth-card">
            <a class="brand" href="${ctx}/login"><span class="brand-mark">P</span> pennywise</a>
            <p class="eyebrow">A BETTER MONEY HABIT STARTS HERE</p>
            <h1>Make every rupee count.</h1>
            <p class="muted">Create your personal space to track income, spending and savings.</p>
            <c:if test="${not empty error}">
                <div class="alert error"><c:out value="${error}"/></div>
            </c:if>
            <c:if test="${not empty success}">
                <div class="alert success"><c:out value="${success}"/></div>
            </c:if>
            <form method="post" action="${ctx}/register">
                <input type="hidden" name="csrfToken" value="${csrf}">
                <label>Full name</label>
                <input name="fullName" maxlength="120" required autocomplete="name" placeholder="Your name">
                <label>Email address</label>
                <input type="email" name="email" maxlength="190" required autocomplete="email" placeholder="you@example.com">
                <label>Password</label>
                <input type="password" name="password" minlength="8" maxlength="72" required autocomplete="new-password" placeholder="At least 8 characters">
                <label>Confirm password</label>
                <input type="password" name="confirmPassword" minlength="8" maxlength="72" required autocomplete="new-password" placeholder="Repeat your password">
                <button class="btn primary full">Create account</button>
            </form>
            <p class="switch">Already have an account? <a href="${ctx}/login">Sign in</a></p>
            <p class="tiny">Your password is protected with BCrypt hashing.</p>
        </main>
    </body>
</html>