package servlet;

import dao.UserDAO;
import model.User;
import util.PasswordUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

/**
 * =====================================================================
 * Member 4 Deliverable: Authentication Controller Servlet
 * Project: Personal Expense Tracker
 * =====================================================================
 * Handles user authentication actions:
 * - Registration (with validation & duplicate checks)
 * - Login (with credential verification & session fixation protection)
 * - Logout (with session invalidation)
 */
@WebServlet("/auth")
public class AuthServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private UserDAO userDAO;

    @Override
    public void init() throws ServletException {
        super.init();
        this.userDAO = new UserDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String action = request.getParameter("action");
        if (action == null) {
            action = "";
        }

        switch (action) {
            case "logout":
                handleLogout(request, response);
                break;
            case "login":
                request.getRequestDispatcher("/login.jsp").forward(request, response);
                break;
            case "register":
                request.getRequestDispatcher("/register.jsp").forward(request, response);
                break;
            default:
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                break;
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String action = request.getParameter("action");
        if (action == null) {
            action = "";
        }

        switch (action) {
            case "register":
                handleRegister(request, response);
                break;
            case "login":
                handleLogin(request, response);
                break;
            case "logout":
                handleLogout(request, response);
                break;
            default:
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                break;
        }
    }

    /**
     * Handles user registration with comprehensive server-side validation.
     */
    private void handleRegister(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String username = request.getParameter("username");
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String confirmPassword = request.getParameter("confirmPassword");

        // Trim values
        username = (username != null) ? username.trim() : "";
        email = (email != null) ? email.trim() : "";
        password = (password != null) ? password : "";
        confirmPassword = (confirmPassword != null) ? confirmPassword : "";

        // Server-side validation
        if (username.isEmpty() || email.isEmpty() || password.isEmpty() || confirmPassword.isEmpty()) {
            request.setAttribute("errorMessage", "All fields are required.");
            request.setAttribute("username", username);
            request.setAttribute("email", email);
            request.getRequestDispatcher("/register.jsp").forward(request, response);
            return;
        }

        if (username.length() < 3 || username.length() > 50) {
            request.setAttribute("errorMessage", "Username must be between 3 and 50 characters.");
            request.setAttribute("username", username);
            request.setAttribute("email", email);
            request.getRequestDispatcher("/register.jsp").forward(request, response);
            return;
        }

        if (!email.matches("^[A-Za-z0-9+_.-]+@(.+)$") || email.length() > 100) {
            request.setAttribute("errorMessage", "Please provide a valid email address.");
            request.setAttribute("username", username);
            request.setAttribute("email", email);
            request.getRequestDispatcher("/register.jsp").forward(request, response);
            return;
        }

        if (password.length() < 6) {
            request.setAttribute("errorMessage", "Password must be at least 6 characters long.");
            request.setAttribute("username", username);
            request.setAttribute("email", email);
            request.getRequestDispatcher("/register.jsp").forward(request, response);
            return;
        }

        if (!password.equals(confirmPassword)) {
            request.setAttribute("errorMessage", "Passwords do not match.");
            request.setAttribute("username", username);
            request.setAttribute("email", email);
            request.getRequestDispatcher("/register.jsp").forward(request, response);
            return;
        }

        // Duplicate checks
        if (userDAO.existsByUsername(username)) {
            request.setAttribute("errorMessage", "Username is already taken. Please choose another.");
            request.setAttribute("username", username);
            request.setAttribute("email", email);
            request.getRequestDispatcher("/register.jsp").forward(request, response);
            return;
        }

        if (userDAO.existsByEmail(email)) {
            request.setAttribute("errorMessage", "An account with this email already exists.");
            request.setAttribute("username", username);
            request.setAttribute("email", email);
            request.getRequestDispatcher("/register.jsp").forward(request, response);
            return;
        }

        // Hash password securely with PBKDF2
        String passwordHash = PasswordUtil.hashPassword(password);
        User newUser = new User(username, email, passwordHash);

        boolean registered = userDAO.registerUser(newUser);
        if (registered) {
            // Post-Redirect-Get with success message
            HttpSession session = request.getSession(true);
            session.setAttribute("successMessage", "Registration successful! Please log in.");
            response.sendRedirect(request.getContextPath() + "/login.jsp");
        } else {
            request.setAttribute("errorMessage", "Registration failed due to a server error. Please try again.");
            request.setAttribute("username", username);
            request.setAttribute("email", email);
            request.getRequestDispatcher("/register.jsp").forward(request, response);
        }
    }

    /**
     * Handles user login with timing attack protection & session fixation prevention.
     */
    private void handleLogin(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String email = request.getParameter("email");
        String password = request.getParameter("password");

        email = (email != null) ? email.trim() : "";
        password = (password != null) ? password : "";

        if (email.isEmpty() || password.isEmpty()) {
            request.setAttribute("errorMessage", "Please enter both email and password.");
            request.setAttribute("email", email);
            request.getRequestDispatcher("/login.jsp").forward(request, response);
            return;
        }

        // Validate credentials against DB
        User user = userDAO.validateLogin(email, password);
        if (user == null) {
            // OWASP standard: generic error message to prevent user enumeration
            request.setAttribute("errorMessage", "Invalid email or password.");
            request.setAttribute("email", email);
            request.getRequestDispatcher("/login.jsp").forward(request, response);
            return;
        }

        // Authentication Successful
        // Prevent session fixation attack by regenerating session ID
        HttpSession oldSession = request.getSession(false);
        if (oldSession != null) {
            oldSession.invalidate();
        }
        HttpSession session = request.getSession(true);
        request.changeSessionId();

        // Store user identity in session
        session.setAttribute("user_id", user.getId());
        session.setAttribute("username", user.getUsername());
        session.setAttribute("email", user.getEmail());

        // Redirect to dashboard (Post-Redirect-Get)
        response.sendRedirect(request.getContextPath() + "/expenses");
    }

    /**
     * Handles user logout by invalidating the current HTTP session.
     */
    private void handleLogout(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        HttpSession session = request.getSession(false);
        if (session != null) {
            session.invalidate();
        }
        response.sendRedirect(request.getContextPath() + "/login.jsp?logout=true");
    }
}

