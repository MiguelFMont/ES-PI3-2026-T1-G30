// Autor: Miguel Fernandes Monteiro
// RA: 25014808

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppHttpClient {
  static String get baseUrl {
    final configuredUrl = dotenv.env['API_BASE_URL']?.trim();

    if (configuredUrl != null && configuredUrl.isNotEmpty) {
      return _withoutTrailingSlash(configuredUrl);
    }

    if (kIsWeb) {
      return 'http://localhost:3000/v1';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/v1';
    }

    return 'http://127.0.0.1:3000/v1';
  }

  static String _withoutTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
