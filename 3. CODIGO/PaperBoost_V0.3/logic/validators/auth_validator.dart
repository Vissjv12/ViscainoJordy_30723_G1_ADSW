class AuthValidator {
  const AuthValidator._();

  /// Valida si un correo electrónico tiene un formato correcto.
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  /// Valida si la contraseña cumple con los requisitos mínimos de longitud.
  /// Pensado para un uso sencillo y accesible para personas mayores.
  static bool isValidPassword(String password) {
    return password.trim().length >= 6;
  }
}