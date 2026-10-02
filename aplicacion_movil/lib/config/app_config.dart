class AppConfig {
  static const bool isProduction = bool.fromEnvironment(
    'dart.vm.product',
    defaultValue: false,
  );

  static const String developmentBaseUrl =
      'http://192.168.1.6:3000/api';

  static const String productionBaseUrl =
      'https://aplicaci-n-movil.onrender.com/api';

  static String get baseUrl =>
      isProduction ? productionBaseUrl : developmentBaseUrl;

  static void validate() {
    if (isProduction && !baseUrl.startsWith('https://')) {
      throw StateError(
        'La configuración de producción requiere HTTPS.',
      );
    }
  }
}