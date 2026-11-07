import 'package:flutter/foundation.dart';

/// Endereço da API.
///
/// - Emulador Android: o PC é visto como 10.0.2.2 (padrão).
/// - iOS/desktop/web: localhost.
/// - Celular físico: `--dart-define=API_BASE_URL=http://IP_DO_PC:8000`.
abstract final class ApiConfig {
  static const _fromEnv = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }
}
