import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mesclainvest/core/network/http_client.dart';
import 'package:mesclainvest/core/storage/session_manager.dart';
import 'package:mesclainvest/features/balcao/models/holding_model.dart';
import 'package:mesclainvest/features/balcao/models/offer_model.dart';
import 'package:mesclainvest/features/portfolio/domain/models/operacao_model.dart';
import 'package:mesclainvest/features/portfolio/domain/models/startup_model.dart';

class BalcaoApiService {
  Future<List<HoldingModel>> getMyHoldings() async {
    final body = await _get(
      '/wallet/holdings',
      fallbackMessage: 'Não foi possível carregar suas holdings.',
    );

    final items = (body['items'] as List<dynamic>? ?? const []);
    return items
        .map((item) => HoldingModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<OfferModel>> getMyActiveOffers() async {
    final body = await _get(
      '/offers/my-active',
      fallbackMessage: 'Não foi possível carregar suas ofertas ativas.',
    );

    final items = (body['items'] as List<dynamic>? ?? const []);
    return items
        .map((item) => OfferModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<OfferModel>> getMarketOffers() async {
    final body = await _get(
      '/offers/market',
      fallbackMessage: 'Não foi possível carregar as ofertas do mercado.',
    );

    final items = (body['items'] as List<dynamic>? ?? const []);
    return items
        .map((item) => OfferModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<StartupModel>> getStartups() async {
    final body = await _get(
      '/startups',
      fallbackMessage: 'Não foi possível carregar as startups.',
    );

    final items = (body['data'] as List<dynamic>? ?? const []);
    return items
        .map((item) => StartupModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<OperacaoModel>> getTransactions() async {
    final body = await _get(
      '/wallet/transactions',
      fallbackMessage: 'Não foi possível carregar o histórico de operações.',
    );

    final items = (body['items'] as List<dynamic>? ?? const []);
    return items.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return OperacaoModel.fromJson(map);
    }).toList();
  }

  Future<void> createSellOffer({
    required String startupId,
    required int quantidade,
    required int precoUnitarioCentavos,
  }) async {
    await _post(
      '/offers',
      body: {
        'startupId': startupId,
        'quantidade': quantidade,
        'precoUnitarioCentavos': precoUnitarioCentavos,
      },
      fallbackMessage: 'Não foi possível criar a oferta.',
    );
  }

  Future<void> directSell({
    required String startupId,
    required int quantidade,
  }) async {
    await _post(
      '/trades/direct-sell',
      body: {'startupId': startupId, 'quantidade': quantidade},
      fallbackMessage: 'Não foi possível concluir a venda direta.',
    );
  }

  Future<void> cancelOffer(String offerId) async {
    await _post(
      '/offers/$offerId/cancel',
      fallbackMessage: 'Não foi possível cancelar a oferta.',
    );
  }

  Future<void> acceptOffer(String offerId) async {
    await _post(
      '/offers/$offerId/accept',
      fallbackMessage: 'Não foi possível aceitar a oferta.',
    );
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    required String fallbackMessage,
  }) async {
    final response = await http.get(
      Uri.parse('${AppHttpClient.baseUrl}$path'),
      headers: await _headers(),
    );

    return _handleResponse(
      response,
      path: path,
      fallbackMessage: fallbackMessage,
    );
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? body,
    required String fallbackMessage,
  }) async {
    final response = await http.post(
      Uri.parse('${AppHttpClient.baseUrl}$path'),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );

    return _handleResponse(
      response,
      path: path,
      fallbackMessage: fallbackMessage,
    );
  }

  Future<Map<String, String>> _headers() async {
    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _handleResponse(
    http.Response response, {
    required String path,
    required String fallbackMessage,
  }) {
    final rawBody = response.body;
    final contentType = response.headers['content-type'] ?? '';
    final isJsonResponse = contentType.contains('application/json');
    final isHtmlResponse =
        rawBody.trimLeft().startsWith('<!DOCTYPE') ||
        rawBody.trimLeft().startsWith('<html');

    if (!isJsonResponse && isHtmlResponse) {
      throw Exception(_missingBackendRouteMessage(path));
    }

    final body = _decodeBody(rawBody);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(body, fallbackMessage));
    }

    return body;
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
        'O servidor retornou uma resposta inválida para o balcão. Verifique se o backend configurado está atualizado.',
      );
    }

    return <String, dynamic>{};
  }

  String _missingBackendRouteMessage(String path) {
    return 'O endpoint $path não está disponível no backend configurado para este app. Atualize ou publique a versão mais recente do backend do balcão.';
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

    final error = body['error'];
    if (error is String && error.trim().isNotEmpty) {
      return error;
    }

    return fallbackMessage;
  }
}
