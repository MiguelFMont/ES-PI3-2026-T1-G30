import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mesclainvest/core/network/http_client.dart';

import '../../../core/storage/session_manager.dart';
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

  Future<Map<String, String>> _authorizedHeaders() async {
    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw StartupApiException(
        'Sessão expirada. Faça login novamente.',
        401,
      );
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
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

  Future<int> buscarSaldoDisponivelCentavos() async {
    final headers = await _authorizedHeaders();
    final url = _buildUri('/wallet');

    try {
      final response = await http.get(url, headers: headers).timeout(
        _requestTimeout,
      );

      if (response.statusCode == 200) {
        final body = _decodeJsonObject(response.body);
        return (body['saldoCentavos'] as num? ?? 0).toInt();
      }

      throw StartupApiException(
        _extractErrorMessage(response.body) ??
            'Não foi possível carregar o saldo da carteira.',
        response.statusCode,
      );
    } on TimeoutException {
      throw StartupApiException(
        'A carteira demorou para responder. Tente novamente.',
      );
    } on SocketException {
      throw StartupApiException(
        'Não foi possível conectar ao servidor da carteira.',
      );
    } on FormatException {
      throw StartupApiException(
        'O servidor retornou dados inválidos para a carteira.',
      );
    } catch (e) {
      if (e is StartupApiException) {
        rethrow;
      }

      throw StartupApiException(
        'Não foi possível carregar o saldo disponível agora.',
      );
    }
  }

  Future<StartupPurchaseResult> investirStartup(
    String startupId,
    int quantidade,
  ) async {
    if (startupId.trim().isEmpty || quantidade <= 0) {
      throw StartupApiException(
        'Informe uma quantidade inteira válida.',
        400,
      );
    }

    final headers = await _authorizedHeaders();
    final url = _buildUri('/trades/direct-buy');

    try {
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode({
              'startupId': startupId.trim(),
              'quantidade': quantidade,
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        return StartupPurchaseResult.fromJson(
          _decodeJsonObject(response.body),
        );
      }

      throw StartupApiException(
        _extractErrorMessage(response.body) ??
            'Não foi possível concluir a compra de tokens.',
        response.statusCode,
      );
    } on TimeoutException {
      throw StartupApiException(
        'A compra demorou para responder. Tente novamente.',
      );
    } on SocketException {
      throw StartupApiException(
        'Não foi possível conectar ao servidor de compras.',
      );
    } on FormatException {
      throw StartupApiException(
        'O servidor retornou dados inválidos para esta compra.',
      );
    } catch (e) {
      if (e is StartupApiException) {
        rethrow;
      }

      throw StartupApiException(
        'Não foi possível concluir a compra agora.',
      );
    }
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

  String? _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map) {
          final nestedMessage = error['message'];
          if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
            return nestedMessage.trim();
          }
        }
        if (error is String && error.trim().isNotEmpty) {
          return error.trim();
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

class StartupPurchaseResult {
  final String transactionId;
  final String startupId;
  final int quantidade;
  final int precoUnitarioCentavos;
  final int valorTotalCentavos;
  final int saldoNovoCentavos;

  const StartupPurchaseResult({
    required this.transactionId,
    required this.startupId,
    required this.quantidade,
    required this.precoUnitarioCentavos,
    required this.valorTotalCentavos,
    required this.saldoNovoCentavos,
  });

  factory StartupPurchaseResult.fromJson(Map<String, dynamic> json) {
    return StartupPurchaseResult(
      transactionId: json['transactionId'] as String? ?? '',
      startupId: json['startupId'] as String? ?? '',
      quantidade: (json['quantidade'] as num? ?? 0).toInt(),
      precoUnitarioCentavos: (json['precoUnitarioCentavos'] as num? ?? 0)
          .toInt(),
      valorTotalCentavos: (json['valorTotalCentavos'] as num? ?? 0).toInt(),
      saldoNovoCentavos: (json['saldoNovoCentavos'] as num? ?? 0).toInt(),
    );
  }
}
