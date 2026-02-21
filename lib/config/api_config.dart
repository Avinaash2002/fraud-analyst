/// FraudX Analyst - API Configuration
/// =====================================
/// Handles backend URL configuration for different testing environments.
/// 
/// Switch between:
/// - Android Emulator (10.0.2.2)
/// - Physical Device (your PC's local IP)
/// - Production (Render deployment)

class ApiConfig {
  // ── Choose your environment ────────────────────────────────────────────────
  static const AppEnvironment environment = AppEnvironment.emulator;
  
  // ── Backend URLs ───────────────────────────────────────────────────────────
  static const String _emulatorUrl = 'http://10.0.2.2:8000';
  static const String _localDeviceUrl = 'http://192.168.1.100:8000';  // Replace with your PC's IP
  static const String _productionUrl = 'https://your-app.onrender.com';
  
  // ── Active base URL ────────────────────────────────────────────────────────
  static String get baseUrl {
    switch (environment) {
      case AppEnvironment.emulator:
        return _emulatorUrl;
      case AppEnvironment.localDevice:
        return _localDeviceUrl;
      case AppEnvironment.production:
        return _productionUrl;
    }
  }
  
  // ── API Endpoints ──────────────────────────────────────────────────────────
  static String get predict => '$baseUrl/api/v1/predict';
  static String get models => '$baseUrl/api/v1/models';
  static String get modelsCompare => '$baseUrl/api/v1/models/compare';
  static String get history => '$baseUrl/api/v1/history';
  static String get chat => '$baseUrl/api/v1/chat';
  static String get chatSuggestions => '$baseUrl/api/v1/chat/suggestions';
  
  // ── Timeout settings ───────────────────────────────────────────────────────
  static const Duration timeout = Duration(seconds: 30);
  
  // ── Device ID (for history tracking) ───────────────────────────────────────
  static String? _deviceId;
  
  static String get deviceId {
    _deviceId ??= DateTime.now().millisecondsSinceEpoch.toString();
    return _deviceId!;
  }
}

enum AppEnvironment {
  emulator,
  localDevice,
  production,
}
