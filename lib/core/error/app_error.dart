/// Application error handling
class AppError {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppError({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppError($code): $message';
}

class NetworkError extends AppError {
  final int? statusCode;

  NetworkError({
    required super.message,
    super.code,
    this.statusCode,
    super.originalError,
    super.stackTrace,
  });
}

class TimeoutError extends AppError {
  TimeoutError({
    super.message = 'انتهت مهلة الاتصال',
    super.code = 'TIMEOUT',
    super.originalError,
    super.stackTrace,
  });
}

class ConnectionError extends AppError {
  ConnectionError({
    super.message = 'فشل الاتصال بالخادم',
    super.code = 'CONNECTION_ERROR',
    super.originalError,
    super.stackTrace,
  });
}

class AuthenticationError extends AppError {
  AuthenticationError({
    super.message = 'فشل المصادقة',
    super.code = 'AUTH_ERROR',
    super.originalError,
    super.stackTrace,
  });
}

class ValidationError extends AppError {
  final Map<String, String> fieldErrors;

  ValidationError({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    required this.fieldErrors,
    super.originalError,
    super.stackTrace,
  });
}

class StorageError extends AppError {
  StorageError({
    required super.message,
    super.code = 'STORAGE_ERROR',
    super.originalError,
    super.stackTrace,
  });
}

class ConfigurationError extends AppError {
  ConfigurationError({
    required super.message,
    super.code = 'CONFIG_ERROR',
    super.originalError,
    super.stackTrace,
  });
}

/// Error handler utility
class ErrorHandler {
  ErrorHandler._();

  static AppError handleError(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppError) return error;

    if (error is FormatException) {
      return AppError(
        message: 'صيغة غير صالحة: ${error.message}',
        code: 'FORMAT_ERROR',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is ArgumentError) {
      return AppError(
        message: error.message.toString(),
        code: 'ARGUMENT_ERROR',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is StateError) {
      return AppError(
        message: error.message,
        code: 'STATE_ERROR',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return AppError(
      message: error.toString(),
      code: 'UNKNOWN_ERROR',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static String getUserFriendlyMessage(AppError error) {
    switch (error.code) {
      case 'TIMEOUT':
        return 'انتهت مهلة الاتصال. تحقق من شبكتك وحاول مرة أخرى.';
      case 'CONNECTION_ERROR':
        return 'تعذر الاتصال بالخادم. تحقق من عنوان URL واتصالك بالإنترنت.';
      case 'AUTH_ERROR':
        return 'فشلت المصادقة. تحقق من بيانات الاعتماد الخاصة بك.';
      case 'VALIDATION_ERROR':
        return 'البيانات المدخلة غير صالحة.';
      case 'STORAGE_ERROR':
        return 'حدث خطأ في التخزين. حاول مرة أخرى.';
      case 'FORMAT_ERROR':
        return 'الصيغة غير صالحة.';
      default:
        return error.message;
    }
  }
}
