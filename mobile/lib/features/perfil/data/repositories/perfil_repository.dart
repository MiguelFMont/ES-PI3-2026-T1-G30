// lib/features/perfil/data/repositories/perfil_repository.dart
// Autor: Miguel Fernandes Monteiro — RA: 25014808

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/http_client.dart';
import '../../../../core/storage/session_manager.dart';
import '../../domain/perfil_models.dart';

class PerfilRepository {
  Future<PerfilModel> buscarPerfil() async {
    final token = await SessionManager.getToken();
    if (token == null) throw Exception('Sessão expirada. Faça login novamente.');

    final uri = Uri.parse('${AppHttpClient.baseUrl}/users/me');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return PerfilModel.fromJson(json);
    } else if (response.statusCode == 401) {
      throw Exception('Sessão expirada. Faça login novamente.');
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['erro'] ?? 'Erro ao buscar perfil');
    }
  }

  Future<void> adicionarSaldo(double amount) async {
    final token = await SessionManager.getToken();
    if (token == null) throw Exception('Sessão expirada. Faça login novamente.');

    final uri = Uri.parse('${AppHttpClient.baseUrl}/wallet/add-balance');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'amount': amount}),
    );

    if (response.statusCode == 200) {
      return;
    }

    final body =
        response.body.isNotEmpty ? jsonDecode(response.body) : <String, dynamic>{};
    throw Exception(body['message'] ?? 'Erro ao adicionar saldo');
  }
}
