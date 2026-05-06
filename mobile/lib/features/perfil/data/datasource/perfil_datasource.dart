
// Autor: Miguel Fernandes Monteiro — RA: 25014808

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/http_client.dart';
import '../../../../core/storage/session_manager.dart';

class PerfilDatasource {
  Future<Map<String, dynamic>> buscarPerfil() async {
    final token = await SessionManager.getToken();
    if (token == null) throw Exception('Sessão expirada. Faça login novamente.');

    final response = await http.get(
      Uri.parse('${AppHttpClient.baseUrl}/users/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else if (response.statusCode == 401) {
      throw Exception('Sessão expirada. Faça login novamente.');
    } else {
      throw Exception(data['message'] ?? 'Erro ao buscar perfil.');
    }
  }
}