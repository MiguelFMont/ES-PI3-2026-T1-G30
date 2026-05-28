import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mesclainvest/core/network/http_client.dart';
import 'package:mesclainvest/core/storage/session_manager.dart';

import '../domain/startup_model.dart';
import 'startup_mock.dart';

class StartupService {
  static const Duration _requestTimeout = Duration(seconds: 10);

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final baseUri = Uri.parse(AppHttpClient.baseUrl);
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    return baseUri.replace(
      path: '${baseUri.path}$normalizedPath',
      queryParameters: queryParameters,
    );
  }

  Future<List<Startup>> listarStartups({String? estagio}) async {
    if (kUseMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (estagio == null || estagio.isEmpty) return List.of(mockStartups);
      return mockStartups.where((s) => s.estagio == estagio).toList();
    }

    final url = _buildUri(
      '/startups',
      estagio != null && estagio.isNotEmpty ? {'estagio': estagio} : null,
    );

    try {
      final response = await http.get(url).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final body = _decodeJsonObject(response.body);
        final data = body['data'];

        if (data is! List) {
          throw StartupApiException(
            'O servidor retornou um catálogo inválido.',
          );
        }

        return data.map((item) => Startup.fromJson(_asJsonMap(item))).toList();
      }

      throw StartupApiException(
        _resolveListErrorMessage(response),
        response.statusCode,
      );
    } on TimeoutException {
      throw StartupApiException(
        'O catálogo demorou para responder. Tente novamente.',
      );
    } on SocketException {
      throw StartupApiException(
        'Não foi possível conectar ao catálogo. Verifique a URL da API e tente novamente.',
      );
    } on FormatException {
      throw StartupApiException(
        'O servidor retornou dados inválidos para o catálogo.',
      );
    } catch (e) {
      if (e is StartupApiException) {
        rethrow;
      }
      throw StartupApiException(
        'Não foi possível carregar o catálogo agora. Tente novamente em instantes.',
      );
    }
  }

  Future<Startup> buscarStartupPorId(String startupId) async {
    if (kUseMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return mockStartups.firstWhere(
        (startup) => startup.id == startupId,
        orElse: () => throw StartupApiException('Startup nao encontrada.', 404),
      );
    }

    final url = _buildUri('/startups/$startupId');

    try {
      final response = await http.get(url).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final body = _decodeJsonObject(response.body);
        return Startup.fromJson(_asJsonMap(body['data']));
      }

      if (response.statusCode == 404) {
        throw StartupApiException('Startup nao encontrada.', 404);
      }
      throw StartupApiException(
        _extractErrorMessage(response.body) ??
            'Erro ao buscar startup: ${response.statusCode}',
        response.statusCode,
      );
    } on TimeoutException {
      throw StartupApiException(
        'Os detalhes da startup demoraram para responder. Tente novamente.',
      );
    } on SocketException {
      throw StartupApiException(
        'Não foi possível conectar ao servidor de startups.',
      );
    } on FormatException {
      throw StartupApiException(
        'O servidor retornou dados inválidos para esta startup.',
      );
    } catch (e) {
      if (e is StartupApiException) {
        rethrow;
      }
      throw StartupApiException(
        'Não foi possível carregar os detalhes da startup agora.',
      );
    }
  }

  Future<bool> investirStartup(String startupId, int quantidade) async {
    final normalizedStartupId = startupId.trim();
    if (normalizedStartupId.isEmpty || quantidade <= 0) {
      return false;
    }

    if (kUseMock) {
      await Future.delayed(const Duration(seconds: 2));
      return true;
    }

    final url = _buildUri('/trades/direct-buy');

    try {
      final response = await http
          .post(
            url,
            headers: await _authenticatedHeaders(),
            body: jsonEncode({
              'startupId': normalizedStartupId,
              'quantidade': quantidade,
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }

      throw StartupApiException(
        _extractErrorMessage(response.body) ??
            _resolveInvestmentErrorMessage(response.statusCode),
        response.statusCode,
      );
    } on TimeoutException {
      throw StartupApiException(
        'A compra demorou para responder. Tente novamente.',
      );
    } on SocketException {
      throw StartupApiException(
        'Não foi possível conectar ao servidor para concluir a compra.',
      );
    } catch (e) {
      if (e is StartupApiException) {
        rethrow;
      }
      throw StartupApiException(
        'Não foi possível concluir o investimento agora.',
      );
    }
  }

  Future<Map<String, String>> _authenticatedHeaders() async {
    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw StartupApiException('Sessão expirada. Faça login novamente.', 401);
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeJsonObject(String body) {
    final decoded = jsonDecode(body);
    return _asJsonMap(decoded);
  }

  Map<String, dynamic> _asJsonMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    throw const FormatException('JSON object expected.');
  }

  String _resolveListErrorMessage(http.Response response) {
    if (response.statusCode >= 500) {
      return 'O catálogo está indisponível no momento. Tente novamente mais tarde.';
    }

    return _extractErrorMessage(response.body) ??
        'Erro ao buscar startups: ${response.statusCode}';
  }

  String _resolveInvestmentErrorMessage(int statusCode) {
    return switch (statusCode) {
      401 => 'Sessão expirada. Faça login novamente.',
      404 => 'Startup não encontrada.',
      409 => 'Não foi possível concluir a compra com os dados atuais.',
      >= 500 => 'O serviço de investimentos está indisponível no momento.',
      _ => 'Erro ao investir na startup: $statusCode',
    };
  }

  String? _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is String && error.trim().isNotEmpty) {
          return error.trim();
        }
        if (error is Map) {
          final message = error['message'];
          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        }
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } on FormatException {
      return null;
    }

    return null;
  }
}

class StartupApiException implements Exception {
  final String message;
  final int? statusCode;

  StartupApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'StartupApiException: $message (Status: $statusCode)';
}
