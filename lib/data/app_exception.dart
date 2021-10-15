class AppException implements Exception {
  final String? message;
  final String? code;

  AppException([this.message = '', this.code]);

  @override
  String toString() {
    if (message == null) {
      return 'AppException';
    }
    return 'AppException: $message (${code ?? 0})';
  }
}