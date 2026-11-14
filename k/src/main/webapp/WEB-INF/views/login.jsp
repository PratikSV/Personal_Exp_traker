<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <title>Sign in · Pennywise</title>
        <link rel="stylesheet" href="${ctx}/assets/css/app.css">
    </head>
    <body class="auth-body">
        <main class="auth-card">
            <a class="brand" href="${ctx}/login"><span class="brand-mark">P</span> pennywise</a>
            <p class="eyebrow">YOUR MONEY, IN FOCUS</p>
            <h1>Welcome back.</h1>
            <p class="muted">Sign in to see where your money goes.</p>
            <c:if test="${not empty error}">
                <div class="alert error"><c:out value="${error}"/></div>
            </c:if>
            <form method="post" action="${ctx}/login">
                <input type="hidden" name="csrfToken" value="${csrf}">
                <label>Email address</label>
                <input type="email" name="email" required autocomplete="email" placeholder="you@example.com">
                <label>Password</label>
                <input type="password" name="password" required autocomplete="current-password" placeholder="Your password">
                <button class="btn primary full">Sign in</button>
            </form>
            <p class="switch">New here? <a href="${ctx}/register">Create an account</a></p>
        </main>
    </body>
</html>