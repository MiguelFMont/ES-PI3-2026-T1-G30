/*
Autora: Maria Julia Lazarini Oleto
RA: 25006031

significado do arquivo:
modelo da carteira do usuario
representa os dados gerais da carteira do usuario
o que aparece no card principal da tela
*/

import 'participacao_model.dart';
import 'operacao_model.dart';

class WalletModel {
  final String uid;
  final double saldoCentavos;
  final double valorTotalCarteiraDashboard;
  final double totalInvestidoDashboard;
  final double lucroTotalDashboard;
  final double retornoPercentDashboard;
  final List<double> pontosGrafico;
  final List<ParticipacaoModel> participacoes;
  final List<OperacaoModel> operacoes;

  const WalletModel({
    required this.uid,
    required this.saldoCentavos,
    required this.valorTotalCarteiraDashboard,
    required this.totalInvestidoDashboard,
    required this.lucroTotalDashboard,
    required this.retornoPercentDashboard,
    required this.pontosGrafico,
    required this.participacoes,
    required this.operacoes,
  });

  double get saldo => saldoCentavos / 100;

  double get valorTotalCarteira => valorTotalCarteiraDashboard;

  double get totalInvestido => totalInvestidoDashboard;

  double get lucroTotal => lucroTotalDashboard;

  double get retornoPercent => retornoPercentDashboard;

  // converte o valor do dashboard para double, pois ele pode vir como string ou número
  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll('%', '').replaceAll(',', '.')) ??
          0.0;
    }
    return 0.0;
  }

  // extrai os pontos do gráfico do dashboard
  static List<double> _pontosFromDashboard(Map<String, dynamic> dashboardMap) {
    final pontos = dashboardMap['pontosGrafico'];
    if (pontos is! List) return const [];

    return pontos
        .map((ponto) {
          if (ponto is num) return ponto.toDouble();
          if (ponto is Map<String, dynamic>) return _toDouble(ponto['valor']);
          if (ponto is Map) return _toDouble(ponto['valor']);
          return 0.0;
        })
        .where((valor) => valor > 0)
        .toList();
  }

  // método factory que cria um walletmoedl a partir do dados do dashboard, participações e operações
  factory WalletModel.fromDashboard(
    String uid,
    Map<String, dynamic> dashboardMap,
    List<ParticipacaoModel> participacoes,
    List<OperacaoModel> operacoes,
  ) {
    return WalletModel(
      uid: uid,
      saldoCentavos: (_toDouble(dashboardMap['saldoDisponivel']) * 100)
          .toInt()
          .toDouble(),
      valorTotalCarteiraDashboard: _toDouble(
        dashboardMap['valorTotalCarteira'],
      ),
      totalInvestidoDashboard: _toDouble(dashboardMap['totalInvestido']),
      lucroTotalDashboard: _toDouble(dashboardMap['lucro']),
      retornoPercentDashboard: _toDouble(dashboardMap['retorno']),
      pontosGrafico: _pontosFromDashboard(dashboardMap),
      participacoes: participacoes,
      operacoes: operacoes,
    );
  }
}
