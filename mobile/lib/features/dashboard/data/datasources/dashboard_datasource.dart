import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/http_client.dart';
import '../../../../core/storage/session_manager.dart';
import '../models/dashboard_models.dart';

class DashboardDatasource {
  Future<DashboardSummaryModel> getSummary() async {
    if (await SessionManager.emModoTeste()) {
      return _demoSummary();
    }

    final body = await _get('/wallet/dashboard', 'Erro ao buscar resumo do dashboard.');
    final dashboard = body['dashboard'];

    if (dashboard is! Map<String, dynamic>) {
      throw Exception('Resposta invalida ao buscar resumo do dashboard.');
    }

    return DashboardSummaryModel.fromJson(dashboard);
  }

  Future<List<HoldingModel>> getHoldings() async {
    if (await SessionManager.emModoTeste()) {
      return const [];
    }

    final body = await _get('/wallet/holdings', 'Erro ao buscar posicoes investidas.');
    return _parseItems(
      body,
      HoldingModel.fromJson,
    ).where((holding) => holding.totalTokens > 0).toList();
  }

  Future<List<TransactionModel>> getTransactions() async {
    if (await SessionManager.emModoTeste()) {
      return _demoTransactions();
    }

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

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
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

  DashboardSummaryModel _demoSummary() {
    final now = DateTime.now();
    final values = <double>[39000, 40500, 39800, 41200, 40750, 42105];

    return DashboardSummaryModel(
      saldoDisponivel: 50000,
      valorTotalCarteira: 42105,
      totalInvestido: 38217.5,
      lucro: 3887.5,
      retorno: 10.45,
      pontosGrafico: [
        for (var i = 0; i < values.length; i++)
          DashboardChartPointModel(
            data: now.subtract(Duration(days: values.length - i)).toIso8601String(),
            valor: values[i],
          ),
      ],
    );
  }

  List<TransactionModel> _demoTransactions() {
    final now = DateTime.now();

    return [
      TransactionModel(
        tipo: 'VENDA_DIRETA',
        nomeStartup: 'HealthAI',
        detalhes: '120 tokens',
        data: now.subtract(const Duration(days: 2)).toIso8601String(),
        valor: 10716,
        createdAt: now.subtract(const Duration(days: 2)),
        precoUnitario: 89.30,
      ),
      TransactionModel(
        tipo: 'COMPRA_DIRETA',
        nomeStartup: 'EcoTech Solutions',
        detalhes: '90 tokens',
        data: now.subtract(const Duration(days: 6)).toIso8601String(),
        valor: 11295,
        createdAt: now.subtract(const Duration(days: 6)),
        precoUnitario: 125.50,
      ),
    ];
  }
}
