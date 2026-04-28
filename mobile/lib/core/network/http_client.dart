//criado só para não repitir a URL base sempre
// Author: Miguel
// RA: 25014808
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppHttpClient {
  
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:5001/v1';
}


