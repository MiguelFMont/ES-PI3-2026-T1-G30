import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mesclainvest/core/network/http_client.dart';
import 'package:mesclainvest/core/storage/session_manager.dart';

import '../domain/startup_model.dart';
import '../domain/startup_price_point.dart';

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
      throw StartupApiException('Sessão expirada. Faça login novamente.', 401);
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Startup>> listarStartups({String? estagio}) async {
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

  Future<List<StartupPricePoint>> buscarHistoricoPrecos(
    String startupId,
  ) async {
    final normalizedStartupId = startupId.trim();
    if (normalizedStartupId.isEmpty) return const [];

    final url = _buildUri('/startups/$normalizedStartupId/price-history');

    try {
      final response = await http.get(url).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final body = _decodeJsonObject(response.body);
        final data = body['data'] ?? body['items'];
        if (data is! List) return const [];

        return data
            .map((item) => StartupPricePoint.fromJson(_asJsonMap(item)))
            .where((point) => point.preco > 0)
            .toList();
      }

      throw StartupApiException(
        _extractErrorMessage(response.body) ??
            'Erro ao buscar histórico de preço: ${response.statusCode}',
        response.statusCode,
      );
    } on TimeoutException {
      throw StartupApiException(
        'O histórico de preço demorou para responder. Tente novamente.',
      );
    } on SocketException {
      throw StartupApiException(
        'Não foi possível conectar ao histórico de preço.',
      );
    } catch (e) {
      if (e is StartupApiException) {
        rethrow;
      }
      throw StartupApiException(
        'Não foi possível carregar o histórico de preço agora.',
      );
    }
  }

  Future<int> buscarQuantidadeTokensUsuario(String startupId) async {
    final normalizedStartupId = startupId.trim();
    if (normalizedStartupId.isEmpty) return 0;

    final url = _buildUri('/wallet/holdings');

    try {
      final response = await http
          .get(url, headers: await _authorizedHeaders())
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final body = _decodeJsonObject(response.body);
        final items = body['items'];
        if (items is! List) return 0;

        for (final item in items) {
          final map = _asJsonMap(item);
          if ('${map['startupId']}' == normalizedStartupId) {
            return _intFromJson(map['quantidade']);
          }
        }
        return 0;
      }

      throw StartupApiException(
        _extractErrorMessage(response.body) ??
            'Erro ao buscar participação: ${response.statusCode}',
        response.statusCode,
      );
    } on TimeoutException {
      throw StartupApiException(
        'A carteira demorou para responder. Tente novamente.',
      );
    } on SocketException {
      throw StartupApiException('Não foi possível conectar à carteira.');
    } catch (e) {
      if (e is StartupApiException) {
        rethrow;
      }
      throw StartupApiException(
        'Não foi possível carregar sua participação agora.',
      );
    }
  }

  Future<int> buscarSaldoDisponivelCentavos() async {
    final headers = await _authorizedHeaders();
    final url = _buildUri('/wallet');

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(_requestTimeout);

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
    final normalizedStartupId = startupId.trim();
    if (normalizedStartupId.isEmpty || quantidade <= 0) {
      throw StartupApiException('Informe uma quantidade inteira válida.', 400);
    }

    final headers = await _authorizedHeaders();
    final url = _buildUri('/trades/direct-buy');

    try {
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode({
              'startupId': normalizedStartupId,
              'quantidade': quantidade,
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        return StartupPurchaseResult.fromJson(_decodeJsonObject(response.body));
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

      throw StartupApiException('Não foi possível concluir a compra agora.');
    }
  }

  Future<StartupSellResult> venderStartup(
    String startupId,
    int quantidade,
  ) async {
    final normalizedStartupId = startupId.trim();
    if (normalizedStartupId.isEmpty || quantidade <= 0) {
      throw StartupApiException('Informe uma quantidade inteira válida.', 400);
    }

    final headers = await _authorizedHeaders();
    final url = _buildUri('/trades/direct-sell');

    try {
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode({
              'startupId': normalizedStartupId,
              'quantidade': quantidade,
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        return StartupSellResult.fromJson(_decodeJsonObject(response.body));
      }

      throw StartupApiException(
        _extractErrorMessage(response.body) ??
            _resolveDirectSellErrorMessage(response.statusCode),
        response.statusCode,
      );
    } on TimeoutException {
      throw StartupApiException(
        'A venda demorou para responder. Tente novamente.',
      );
    } on SocketException {
      throw StartupApiException(
        'Não foi possível conectar ao servidor para concluir a venda.',
      );
    } on FormatException {
      throw StartupApiException(
        'O servidor retornou dados inválidos para esta venda.',
      );
    } catch (e) {
      if (e is StartupApiException) {
        rethrow;
      }
      throw StartupApiException('Não foi possível concluir a venda agora.');
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

  int _intFromJson(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  String _resolveListErrorMessage(http.Response response) {
    if (response.statusCode >= 500) {
      return 'O catálogo está indisponível no momento. Tente novamente mais tarde.';
    }

    return _extractErrorMessage(response.body) ??
        'Erro ao buscar startups: ${response.statusCode}';
  }

  String _resolveDirectSellErrorMessage(int statusCode) {
    return switch (statusCode) {
      401 => 'Sessão expirada. Faça login novamente.',
      404 => 'Startup não encontrada.',
      409 => 'Não foi possível concluir a venda com os dados atuais.',
      >= 500 => 'O serviço de investimentos está indisponível no momento.',
      _ => 'Erro ao vender tokens da startup: $statusCode',
    };
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

class StartupSellResult {
  final String transactionId;
  final String startupId;
  final int quantidade;
  final int precoUnitarioCentavos;
  final int valorTotalCentavos;
  final int saldoNovoCentavos;

  const StartupSellResult({
    required this.transactionId,
    required this.startupId,
    required this.quantidade,
    required this.precoUnitarioCentavos,
    required this.valorTotalCentavos,
    required this.saldoNovoCentavos,
  });

  factory StartupSellResult.fromJson(Map<String, dynamic> json) {
    return StartupSellResult(
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
