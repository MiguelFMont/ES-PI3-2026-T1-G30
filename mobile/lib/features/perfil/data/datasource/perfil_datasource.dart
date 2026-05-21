// Autor: Miguel Fernandes Monteiro — RA: 25014808

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/http_client.dart';
import '../../../../core/storage/session_manager.dart';

class PerfilDatasource {
  Future<Map<String, String>> get _headers async {
    final token = await SessionManager.getToken();
    if (token == null) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }
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

    if (response.statusCode == 200) return data;

    if (response.statusCode == 401 || response.statusCode == 404) {
      await SessionManager.fazerLogout();
      throw Exception('Sessão inválida. Faça login novamente.');
    }

    throw Exception(data['message'] ?? 'Erro ao buscar perfil.');
  }

  Future<void> atualizarPerfil({
    required String nome,
    required String telefone,
  }) async {
    final response = await http.patch(
      Uri.parse('${AppHttpClient.baseUrl}/users/me'),
      headers: await _headers,
      body: jsonEncode({'nome': nome, 'telefone': telefone}),
    );

    if (response.statusCode == 200 || response.statusCode == 204) return;

    try {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Erro ao atualizar perfil.');
    } catch (_) {
      throw Exception('Erro ao atualizar perfil (${response.statusCode}).');
    }
  }

  // ───── MFA ─────

  /// Solicita ao backend a geração do secret e retorna o QR code em base64
  Future<Map<String, dynamic>> setupMfa() async {
    final response = await http.post(
      Uri.parse('${AppHttpClient.baseUrl}/auth/mfa/setup'),
      headers: await _headers,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data['data'];
    throw Exception(data['message'] ?? 'Erro ao iniciar configuração do MFA.');
  }

  /// Envia o código gerado pelo app autenticador para ativar o MFA
  Future<void> verifyMfa(String code) async {
    final response = await http.post(
      Uri.parse('${AppHttpClient.baseUrl}/auth/mfa/verify'),
      headers: await _headers,
      body: jsonEncode({'code': code}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return;
    throw Exception(data['message'] ?? 'Código inválido.');
  }

  Future<void> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    final response = await http.patch(
      Uri.parse('${AppHttpClient.baseUrl}/users/me/senha'),
      headers: await _headers,
      body: jsonEncode({'senhaAtual': senhaAtual, 'novaSenha': novaSenha}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return;
    throw Exception(data['message'] ?? 'Erro ao alterar senha.');
  }
}
