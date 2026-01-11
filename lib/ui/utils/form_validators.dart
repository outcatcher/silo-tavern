/// Form validation utilities
class FormValidators {
  /// Validates that a field is not empty
  static String? notEmpty(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty) {
      return 'Please enter a $fieldName';
    }
    return null;
  }

  /// Validates that a URL is properly formatted
  static String? validUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a URL';
    }
    if (!RegExp(r'^https?:\/\/').hasMatch(value)) {
      return 'Please enter a valid URL (http:// or https://)';
    }
    return null;
  }

  /// Validates username field
  static String? validUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your username';
    }
    return null;
  }

  /// Validates password field
  static String? validPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }
}
