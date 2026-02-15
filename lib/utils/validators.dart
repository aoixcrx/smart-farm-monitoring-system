"""
Input validation utilities for Flutter
Centralized validation functions for all forms
"""

class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult({required this.isValid, this.errorMessage});
}

class ValidatorUtils {
  // Email validation
  static ValidationResult validateEmail(String email) {
    if (email.isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Email is required',
      );
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Please enter a valid email address',
      );
    }

    return ValidationResult(isValid: true);
  }

  // Username validation
  static ValidationResult validateUsername(String username) {
    if (username.isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Username is required',
      );
    }

    if (username.length < 3) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Username must be at least 3 characters',
      );
    }

    if (username.length > 50) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Username must not exceed 50 characters',
      );
    }

    final usernameRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!usernameRegex.hasMatch(username)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Username can only contain letters, numbers, _ and -',
      );
    }

    return ValidationResult(isValid: true);
  }

  // Password validation
  static ValidationResult validatePassword(String password) {
    if (password.isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Password is required',
      );
    }

    if (password.length < 6) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Password must be at least 6 characters',
      );
    }

    if (password.length > 100) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Password must not exceed 100 characters',
      );
    }

    return ValidationResult(isValid: true);
  }

  // Password strength validation
  static ValidationResult validatePasswordStrength(String password) {
    final validation = validatePassword(password);
    if (!validation.isValid) return validation;

    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasNumbers = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    int strength = 0;
    if (hasUppercase) strength++;
    if (hasLowercase) strength++;
    if (hasNumbers) strength++;
    if (hasSpecialChars) strength++;

    if (strength < 2) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Password should include uppercase, lowercase, numbers, and special characters',
      );
    }

    return ValidationResult(isValid: true);
  }

  // Required field validation
  static ValidationResult validateRequired(String value, String fieldName) {
    if (value.isEmpty || value.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: '$fieldName is required',
      );
    }

    return ValidationResult(isValid: true);
  }

  // Number validation
  static ValidationResult validateNumber(String value, {int? minValue, int? maxValue}) {
    if (value.isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Number is required',
      );
    }

    final number = int.tryParse(value);
    if (number == null) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Please enter a valid number',
      );
    }

    if (minValue != null && number < minValue) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Value must be at least $minValue',
      );
    }

    if (maxValue != null && number > maxValue) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Value must not exceed $maxValue',
      );
    }

    return ValidationResult(isValid: true);
  }

  // Double validation
  static ValidationResult validateDouble(String value, {double? minValue, double? maxValue}) {
    if (value.isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Number is required',
      );
    }

    final number = double.tryParse(value);
    if (number == null) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Please enter a valid decimal number',
      );
    }

    if (minValue != null && number < minValue) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Value must be at least $minValue',
      );
    }

    if (maxValue != null && number > maxValue) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Value must not exceed $maxValue',
      );
    }

    return ValidationResult(isValid: true);
  }

  // Date validation
  static ValidationResult validateDate(String dateString) {
    if (dateString.isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Date is required',
      );
    }

    try {
      DateTime.parse(dateString);
      return ValidationResult(isValid: true);
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Please enter a valid date (YYYY-MM-DD)',
      );
    }
  }

  // Phone number validation
  static ValidationResult validatePhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Phone number is required',
      );
    }

    final phoneRegex = RegExp(r'^[+]?[(]?[0-9]{3}[)]?[-\s.]?[0-9]{3}[-\s.]?[0-9]{4,6}$');
    if (!phoneRegex.hasMatch(phoneNumber)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Please enter a valid phone number',
      );
    }

    return ValidationResult(isValid: true);
  }

  // URL validation
  static ValidationResult validateUrl(String url) {
    if (url.isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'URL is required',
      );
    }

    try {
      Uri.parse(url);
      return ValidationResult(isValid: true);
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Please enter a valid URL',
      );
    }
  }

  // Length validation
  static ValidationResult validateLength(
    String value, {
    required int minLength,
    required int maxLength,
    required String fieldName,
  }) {
    if (value.isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: '$fieldName is required',
      );
    }

    if (value.length < minLength) {
      return ValidationResult(
        isValid: false,
        errorMessage: '$fieldName must be at least $minLength characters',
      );
    }

    if (value.length > maxLength) {
      return ValidationResult(
        isValid: false,
        errorMessage: '$fieldName must not exceed $maxLength characters',
      );
    }

    return ValidationResult(isValid: true);
  }
}
