class GhanaTinValidator {
  static final RegExp _businessTinPattern = RegExp(
    r'^[CGQV][0-9]{9}[A-Z0-9]$',
    caseSensitive: false,
  );

  static String normalize(String tin) {
    return tin.trim().toUpperCase();
  }

  static bool isValidBusinessTin(String tin) {
    return _businessTinPattern.hasMatch(normalize(tin));
  }

  static String get formatHint {
    return 'Use Ghana business TIN format: 1 letter + 9 digits + 1 letter/digit (example: V0004162595).';
  }
}
