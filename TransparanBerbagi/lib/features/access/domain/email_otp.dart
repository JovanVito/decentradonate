abstract final class EmailOtp {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _code = RegExp(r'^[0-9]{6}$');

  static bool validEmail(String? value) => _email.hasMatch(value?.trim() ?? '');

  static bool validCode(String? value) => _code.hasMatch(value ?? '');
}
