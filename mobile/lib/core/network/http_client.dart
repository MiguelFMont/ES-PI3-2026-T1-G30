//criado só para não repitir a URL base sempre
// Author: Miguel
// RA: 25014808
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppHttpClient {
  static String get baseUrl {
    final configuredValue = dotenv.env['API_BASE_URL']?.trim();

    if (configuredValue != null &&
        configuredValue.isNotEmpty &&
        configuredValue.toLowerCase() != 'local') {
      return configuredValue;
    }

    if (kIsWeb) {
      return 'http://localhost:3000/v1';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/v1';
    }

    return 'http://127.0.0.1:3000/v1';
  }
}
