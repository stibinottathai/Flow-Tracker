class AppConstants {
  // API
  static const String baseUrl = 'https://your-api-url.com/api';
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Error Messages
  static const String serverErrorMessage = 'Server error occurred';
  static const String cacheErrorMessage = 'Cache error occurred';
  static const String networkErrorMessage =
      'Please check your internet connection';
  static const String unknownErrorMessage = 'An unknown error occurred';
}
