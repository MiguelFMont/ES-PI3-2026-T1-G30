// Autor: Miguel Fernandes Monteiro — RA: 25014808

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/http_client.dart';

class AuthDatasource {

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${AppHttpClient.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Erro ao realizar login.');
  }

  // ───── MFA Challenge ─────

  Future<Map<String, dynamic>> mfaChallenge(String uid, String tempToken, String code) async {
    final response = await http.post(
      Uri.parse('${AppHttpClient.baseUrl}/auth/mfa/challenge'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid, 'tempToken': tempToken, 'code': code}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Código inválido.');
  }

  Future<void> iniciarCadastro(Map<String, dynamic> dados) async {
    final response = await http.post(
      Uri.parse('${AppHttpClient.baseUrl}/auth/register/iniciar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dados),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final erro = jsonDecode(response.body);
      throw Exception(erro['message'] ?? 'Erro ao iniciar cadastro.');
    }
  }

  Future<void> concluirCadastro(String email, String token, String senha) async {
    final response = await http.post(
      Uri.parse('${AppHttpClient.baseUrl}/auth/register/concluir'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'token': token, 'senha': senha}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final erro = jsonDecode(response.body);
      throw Exception(erro['message'] ?? 'Erro ao validar o código.');
    }
  }

  Future<Map<String, dynamic>> solicitarCodigoRecuperacao(String email) async {
    final response = await http.post(
      Uri.parse('${AppHttpClient.baseUrl}/auth/recuperar-senha'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Erro ao solicitar código.');
  }

  Future<Map<String, dynamic>> redefinirSenha(String email, String token, String novaSenha) async {
    final response = await http.post(
      Uri.parse('${AppHttpClient.baseUrl}/auth/redefinir-senha'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'token': token, 'novaSenha': novaSenha}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Erro ao redefinir senha.');
  }

  Future<Map<String, dynamic>> validarToken(String email, String token) async {
    final response = await http.post(
      Uri.parse('${AppHttpClient.baseUrl}/auth/validar-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'token': token}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Erro ao validar código.');
  }

  Future<void> reenviarTokenCadastro(String email) async {
    final response = await http.post(
      Uri.parse('${AppHttpClient.baseUrl}/auth/register/reenviar-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Erro ao reenviar código.');
    }
  }

  Future<void> logout(String idToken) async {
    final response = await http.post(
      Uri.parse('${AppHttpClient.baseUrl}/auth/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Erro ao realizar logout.');
    }
  }
}