class Validators {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (password.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  static String? validateField(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }
}