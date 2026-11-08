package filter;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.FilterConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

/**
 * =====================================================================
 * Member 4 Deliverable: Authentication & Security Filter
 * Project: Personal Expense Tracker
 * =====================================================================
 * Intercepts all incoming requests ("/*") to enforce authentication.
 * - Allows public access to /auth, login.jsp, register.jsp, and static assets.
 * - Redirects unauthenticated requests to login.jsp.
 * - Prevents authenticated users from seeing login/register (redirects to /expenses).
 * - Applies HTTP no-cache headers to protected responses to prevent browser back-button leaks.
 */
@WebFilter("/*")
public class AuthFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        // No special filter initialization needed
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;

        String contextPath = req.getContextPath();
        String uri = req.getRequestURI();
        // Extract relative path within the context
        String path = uri.substring(contextPath.length());

        // Check if user is logged in
        HttpSession session = req.getSession(false);
        boolean isLoggedIn = (session != null && session.getAttribute("user_id") != null);

        // Define public resource paths
        boolean isStaticResource = path.startsWith("/css/") ||
                                   path.startsWith("/js/") ||
                                   path.startsWith("/images/") ||
                                   path.endsWith(".css") ||
                                   path.endsWith(".js") ||
                                   path.endsWith(".png") ||
                                   path.endsWith(".jpg") ||
                                   path.endsWith(".ico");

        boolean isAuthEndpoint = path.equals("/auth") || path.startsWith("/auth/");
        boolean isLoginPage = path.equals("/login.jsp") || path.equals("/login");
        boolean isRegisterPage = path.equals("/register.jsp") || path.equals("/register");

        // Allow static assets always
        if (isStaticResource) {
            chain.doFilter(request, response);
            return;
        }

        // If user is already logged in and navigates to login or register, redirect to expenses dashboard
        if (isLoggedIn && (isLoginPage || isRegisterPage)) {
            res.sendRedirect(contextPath + "/expenses");
            return;
        }

        // Allow public pages
        if (isAuthEndpoint || isLoginPage || isRegisterPage) {
            chain.doFilter(request, response);
            return;
        }

        // Protected resource: verify authentication
        if (isLoggedIn) {
            // Set security and no-cache headers on protected pages
            res.setHeader("Cache-Control", "no-cache, no-store, must-revalidate"); // HTTP 1.1
            res.setHeader("Pragma", "no-cache"); // HTTP 1.0
            res.setDateHeader("Expires", 0); // Proxies
            
            chain.doFilter(request, response);
        } else {
            // Unauthenticated: redirect to login page
            res.sendRedirect(contextPath + "/login.jsp");
        }
    }

    @Override
    public void destroy() {
        // Cleanup if needed
    }
}

