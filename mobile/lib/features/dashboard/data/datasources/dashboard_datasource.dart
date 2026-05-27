import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/http_client.dart';
import '../../../../core/storage/session_manager.dart';
import '../models/dashboard_models.dart';

class DashboardDatasource {
  Future<DashboardSummaryModel> getSummary() async {
    final body = await _get('/wallet/dashboard', 'Erro ao buscar resumo do dashboard.');
    final dashboard = body['dashboard'];

    if (dashboard is! Map<String, dynamic>) {
      throw Exception('Resposta invalida ao buscar resumo do dashboard.');
    }

    return DashboardSummaryModel.fromJson(dashboard);
  }

  Future<List<HoldingModel>> getHoldings() async {
    final body = await _get('/wallet/holdings', 'Erro ao buscar posicoes investidas.');
    return _parseItems(body, HoldingModel.fromJson);
  }

  Future<List<TransactionModel>> getTransactions() async {
    final body = await _get('/wallet/transactions', 'Erro ao buscar transacoes do dashboard.');
    return _parseItems(body, TransactionModel.fromJson);
  }

  Future<Map<String, dynamic>> _get(String path, String errorMessage) async {
    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sessao expirada. Faca login novamente.');
    }

    final response = await http.get(
      Uri.parse('${AppHttpClient.baseUrl}$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(errorMessage);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Resposta invalida do servidor.');
    }
    return decoded;
  }

  List<T> _parseItems<T>(
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final items = body['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
