// Autor: Miguel Fernandes Monteiro — RA: 25014808

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/http_client.dart';
import '../../../../core/storage/session_manager.dart';
import '../../domain/perfil_models.dart';

class PerfilDatasource {
  Future<Map<String, String>> get _headers async {
    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> buscarPerfil() async {
    return _get(
      '/users/me',
      fallbackMessage: 'Erro ao buscar perfil.',
      logoutOnUnauthorized: true,
    );
  }

  Future<WalletBalanceModel> buscarCarteira() async {
    final data = await _get(
      '/wallet',
      fallbackMessage: 'Não foi possível carregar o saldo da carteira.',
    );

    return WalletBalanceModel.fromJson(data);
  }

  Future<WalletBalanceModel> adicionarSaldo(int valorCentavos) async {
    final data = await _post(
      '/wallet/add-balance',
      body: {'valorCentavos': valorCentavos},
      fallbackMessage: 'Não foi possível adicionar saldo à carteira.',
    );

    return WalletBalanceModel.fromJson(data);
  }

  Future<WalletBalanceModel> sacar(int valorCentavos) async {
    final data = await _post(
      '/wallet/withdraw',
      body: {'valorCentavos': valorCentavos},
      fallbackMessage: 'Não foi possível realizar o saque.',
    );

    return WalletBalanceModel.fromJson(data);
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

    final data = _decodeBody(response.body);
    throw Exception(_extractErrorMessage(data, 'Erro ao atualizar perfil.'));
  }

  Future<Map<String, dynamic>> setupMfa() async {
    final data = await _post(
      '/auth/mfa/setup',
      fallbackMessage: 'Erro ao iniciar configuração do MFA.',
    );

    final nested = data['data'];
    if (nested is Map<String, dynamic>) {
      return nested;
    }

    return <String, dynamic>{};
  }

  Future<void> verifyMfa(String code) async {
    await _post(
      '/auth/mfa/verify',
      body: {'code': code},
      fallbackMessage: 'Código inválido.',
    );
  }

  Future<void> disableMfa() async {
    await _post(
      '/auth/mfa/disable',
      fallbackMessage: 'Erro ao desativar MFA.',
    );
  }

  Future<void> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    await _patch(
      '/users/me/senha',
      body: {'senhaAtual': senhaAtual, 'novaSenha': novaSenha},
      fallbackMessage: 'Erro ao alterar senha.',
    );
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    required String fallbackMessage,
    bool logoutOnUnauthorized = false,
  }) async {
    final response = await http.get(
      Uri.parse('${AppHttpClient.baseUrl}$path'),
      headers: await _headers,
    );

    return _handleResponse(
      response,
      path: path,
      fallbackMessage: fallbackMessage,
      logoutOnUnauthorized: logoutOnUnauthorized,
    );
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? body,
    required String fallbackMessage,
    bool logoutOnUnauthorized = false,
  }) async {
    final response = await http.post(
      Uri.parse('${AppHttpClient.baseUrl}$path'),
      headers: await _headers,
      body: body == null ? null : jsonEncode(body),
    );

    return _handleResponse(
      response,
      path: path,
      fallbackMessage: fallbackMessage,
      logoutOnUnauthorized: logoutOnUnauthorized,
    );
  }

  Future<void> _patch(
    String path, {
    required Map<String, dynamic> body,
    required String fallbackMessage,
  }) async {
    final response = await http.patch(
      Uri.parse('${AppHttpClient.baseUrl}$path'),
      headers: await _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final data = _decodeBody(response.body);
    throw Exception(_extractErrorMessage(data, fallbackMessage));
  }

  Future<Map<String, dynamic>> _handleResponse(
    http.Response response, {
    required String path,
    required String fallbackMessage,
    bool logoutOnUnauthorized = false,
  }) async {
    final rawBody = response.body;
    final contentType = response.headers['content-type'] ?? '';
    final isJsonResponse = contentType.contains('application/json');
    final isHtmlResponse =
        rawBody.trimLeft().startsWith('<!DOCTYPE') ||
        rawBody.trimLeft().startsWith('<html');

    if (!isJsonResponse && isHtmlResponse) {
      throw Exception(
        'O endpoint $path não está disponível no backend configurado para este app.',
      );
    }

    final data = _decodeBody(rawBody);

    if (response.statusCode == 401 ||
        response.statusCode == 403 ||
        (logoutOnUnauthorized && response.statusCode == 404)) {
      if (logoutOnUnauthorized) {
        await SessionManager.fazerLogout();
      }
      throw Exception('Sessão inválida. Faça login novamente.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(data, fallbackMessage));
    }

    return data;
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      throw Exception(
        'O servidor retornou uma resposta inválida. Verifique se o backend configurado está atualizado.',
      );
    }

    return <String, dynamic>{};
  }

  String _extractErrorMessage(
    Map<String, dynamic> body,
    String fallbackMessage,
  ) {
    final nestedError = body['error'];
    if (nestedError is Map<String, dynamic>) {
      final nestedMessage = nestedError['message'];
      if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
        return nestedMessage;
      }
    }

    final message = body['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    final erro = body['erro'];
    if (erro is String && erro.trim().isNotEmpty) {
      return erro;
    }

    if (nestedError is String && nestedError.trim().isNotEmpty) {
      return nestedError;
    }

    return fallbackMessage;
  }
}
