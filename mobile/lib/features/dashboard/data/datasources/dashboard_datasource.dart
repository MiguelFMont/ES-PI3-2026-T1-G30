import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/http_client.dart';
import '../../../../core/storage/session_manager.dart';
import '../models/dashboard_models.dart';

class DashboardDatasource {
  Future<Map<String, String>> _getHeaders() async {
    final token = await SessionManager.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Sessao expirada. Faca login novamente.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<DashboardSummaryModel> getSummary() async {
    final response = await http.get(
      Uri.parse('${AppHttpClient.baseUrl}/wallet/dashboard'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar resumo do dashboard.');
    }

    final body = _decodeResponse(response.body);
    final dashboard = body['dashboard'];

    if (dashboard is! Map<String, dynamic>) {
      throw Exception('Resposta invalida ao buscar resumo do dashboard.');
    }

    return DashboardSummaryModel.fromJson(dashboard);
  }

  Future<List<HoldingModel>> getHoldings() async {
    final response = await http.get(
      Uri.parse('${AppHttpClient.baseUrl}/wallet/holdings'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar posicoes investidas.');
    }

    final body = _decodeResponse(response.body);
    final items = body['items'];

    if (items is! List) return const [];

    return items
        .whereType<Map>()
        .map((item) => HoldingModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<TransactionModel>> getTransactions() async {
    final response = await http.get(
      Uri.parse('${AppHttpClient.baseUrl}/wallet/transactions'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar transacoes do dashboard.');
    }

    final body = _decodeResponse(response.body);
    final items = body['items'];

    if (items is! List) return const [];

    return items
        .whereType<Map>()
        .map(
          (item) => TransactionModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Map<String, dynamic> _decodeResponse(String body) {
    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw Exception('Resposta invalida do servidor.');
  }
}
