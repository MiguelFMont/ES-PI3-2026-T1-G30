import 'dart:convert';
import 'dart:io' show Platform; 
import 'package: flutter/foundation.dart' show KIsWeb;
import 'package:http/http.dart' as http;
import '../domain/startup_model.dart';

class StartupService {
  // URL base do backend
  static String get _baseUrl {
    if (KIsWeb) {
      return 'https://localhost:3000';
    } else if (Platform.isAndroid){
      return 'https://10.0.2.2:3000' // é para o emulador de android
    } else {
      return 'https://127.0.0.1:3000' // para emulador de ios 
    }
  }

  // Busca todas as startups, com filtro opcional por estágio
  Future<List<Startup>> listarStartups({String? estagio}) async {
    final url = estagio != null && estagio.isNotEmpty
        ? Uri.parse('$_baseUrl/startups?estagio=$estagio')
        : Uri.parse('$_baseUrl/startups');

    // Faz a requisição GET
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> data = body['data'];
      return data.map((json) => Startup.fromJson(json)).toList();
    }
    throw Exception('Erro ao buscar startups: ${response.statusCode}');
  }
}