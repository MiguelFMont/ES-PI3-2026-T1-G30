// Autor: Miguel Fernandes Monteiro — RA: 25014808

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/http_client.dart';
import '../../../../core/storage/session_manager.dart';

class PerfilDatasource {
  Future<Map<String, String>> get _headers async {
    final token = await SessionManager.getToken();
    if (token == null) throw Exception('Sessão expirada. Faça login novamente.');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> buscarPerfil() async {
    final response = await http.get(
      Uri.parse('${AppHttpClient.baseUrl}/users/me'),
      headers: await _headers,
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

  /// Envia apenas os campos editáveis via PATCH.
  /// O backend atualiza o documento do usuário autenticado no Firestore.
  Future<void> atualizarPerfil({
    required String nome,
    required String email,
    required String telefone,
  }) async {
    final response = await http.patch(
      Uri.parse('${AppHttpClient.baseUrl}/users/me'),
      headers: await _headers,
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'telefone': telefone,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 204) return;

    // Tenta extrair mensagem de erro estruturada do backend
    try {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Erro ao atualizar perfil.');
    } catch (_) {
      throw Exception('Erro ao atualizar perfil (${response.statusCode}).');
    }
  }
}