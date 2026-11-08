/**
 * =====================================================================
 * Member 5 Deliverable: Client-Side Validation and UI Interactions
 * Project: Personal Expense Tracker
 * =====================================================================
 */

document.addEventListener("DOMContentLoaded", function () {

    // 1. Client-side validation for Registration Form
    const registerForm = document.getElementById("registerForm");
    if (registerForm) {
        registerForm.addEventListener("submit", function (e) {
            let valid = true;

            const username = document.getElementById("username");
            const email = document.getElementById("email");
            const password = document.getElementById("password");
            const confirmPassword = document.getElementById("confirmPassword");

            // Reset previous errors
            clearErrors();

            // Validate Username
            if (!username.value || username.value.trim().length < 3 || username.value.trim().length > 50) {
                showError("usernameError", "Username must be between 3 and 50 characters.");
                valid = false;
            }

            // Validate Email
            const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!email.value || !emailPattern.test(email.value.trim())) {
                showError("emailError", "Please enter a valid email address.");
                valid = false;
            }

            // Validate Password
            if (!password.value || password.value.length < 6) {
                showError("passwordError", "Password must be at least 6 characters.");
                valid = false;
            }

            // Validate Password Match
            if (password.value !== confirmPassword.value) {
                showError("confirmPasswordError", "Passwords do not match.");
                valid = false;
            }

            if (!valid) {
                e.preventDefault();
            }
        });
    }

    // 2. Client-side validation for Login Form
    const loginForm = document.getElementById("loginForm");
    if (loginForm) {
        loginForm.addEventListener("submit", function (e) {
            let valid = true;
            const email = document.getElementById("email");
            const password = document.getElementById("password");

            clearErrors();

            if (!email.value || email.value.trim() === "") {
                showError("emailError", "Email address is required.");
                valid = false;
            }

            if (!password.value || password.value.trim() === "") {
                showError("passwordError", "Password is required.");
                valid = false;
            }

            if (!valid) {
                e.preventDefault();
            }
        });
    }

    // 3. Client-side validation for Add Expense Form
    const addExpenseForm = document.getElementById("addExpenseForm");
    if (addExpenseForm) {
        // Automatically default expense date to today if empty
        const dateInput = document.getElementById("expenseDate");
        if (dateInput && !dateInput.value) {
            const today = new Date().toISOString().split("T")[0];
            dateInput.value = today;
        }

        addExpenseForm.addEventListener("submit", function (e) {
            let valid = true;
            const title = document.getElementById("title");
            const amount = document.getElementById("amount");
            const category = document.getElementById("category");
            const expenseDate = document.getElementById("expenseDate");

            clearErrors();

            if (!title.value || title.value.trim() === "" || title.value.trim().length > 100) {
                showError("titleError", "Title is required (max 100 characters).");
                valid = false;
            }

            const numAmount = parseFloat(amount.value);
            if (isNaN(numAmount) || numAmount <= 0) {
                showError("amountError", "Amount must be a positive number greater than 0.00.");
                valid = false;
            } else if (numAmount > 99999999.99) {
                showError("amountError", "Amount exceeds maximum limit ($99,999,999.99).");
                valid = false;
            }

            if (!category.value || category.value.trim() === "") {
                showError("categoryError", "Please select an expense category.");
                valid = false;
            }

            if (!expenseDate.value) {
                showError("dateError", "Expense date is required.");
                valid = false;
            }

            if (!valid) {
                e.preventDefault();
            }
        });
    }
});

/**
 * Utility to display form field error message
 */
function showError(elementId, message) {
    const errorEl = document.getElementById(elementId);
    if (errorEl) {
        errorEl.textContent = message;
        errorEl.style.display = "block";
    }
}

/**
 * Utility to clear all form error spans
 */
function clearErrors() {
    const errors = document.querySelectorAll(".form-error");
    errors.forEach(function (el) {
        el.textContent = "";
        el.style.display = "none";
    });
}

/**
 * Delete confirmation prompt
 * @param {string} title title of the expense to be deleted
 * @returns {boolean} true if user confirmed, false otherwise
 */
function confirmDelete(title) {
    return confirm("Are you sure you want to delete the expense: \"" + title + "\"?\nThis action cannot be undone.");
}

