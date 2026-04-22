import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/startup_model.dart';

class StartupService {
  // URL base do backend
  static const String _baseUrl = 'http://10.0.2.2:3000';

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