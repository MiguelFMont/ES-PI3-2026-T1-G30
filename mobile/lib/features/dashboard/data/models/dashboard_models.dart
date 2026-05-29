class DashboardSummaryModel {
  const DashboardSummaryModel({
    required this.saldoDisponivel,
    required this.valorTotalCarteira,
    required this.totalInvestido,
    required this.lucro,
    required this.retorno,
    required this.pontosGrafico,
  });

  final double saldoDisponivel;
  final double valorTotalCarteira;
  final double totalInvestido;
  final double lucro;
  final double retorno;
  final List<DashboardChartPointModel> pontosGrafico;

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final pontos = json['pontosGrafico'];

    return DashboardSummaryModel(
      saldoDisponivel: _toDouble(json['saldoDisponivel']),
      valorTotalCarteira: _toDouble(json['valorTotalCarteira']),
      totalInvestido: _toDouble(json['totalInvestido']),
      lucro: _toDouble(json['lucro']),
      retorno: _toDouble(json['retorno']),
      pontosGrafico: pontos is List
          ? pontos
                .whereType<Map>()
                .map(
                  (item) => DashboardChartPointModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class DashboardChartPointModel {
  const DashboardChartPointModel({required this.data, required this.valor});

  final String data;
  final double valor;

  factory DashboardChartPointModel.fromJson(Map<String, dynamic> json) {
    return DashboardChartPointModel(
      data: _toText(json['data']),
      valor: _toDouble(json['valor']),
    );
  }
}

class HoldingModel {
  const HoldingModel({
    required this.nomeStartup,
    required this.setor,
    required this.totalTokens,
    required this.valorInvestido,
    required this.percentualRetorno,
  });

  final String nomeStartup;
  final String setor;
  final double totalTokens;
  final double valorInvestido;
  final double percentualRetorno;

  factory HoldingModel.fromJson(Map<String, dynamic> json) {
    final quantidade = _toDouble(json['quantidade']);
    final quantidadeBloqueada = _toDouble(json['quantidadeBloqueada']);
    final precoMedioCentavos = _toDouble(json['precoMedioCentavos']);
    final quantidadeTotal = quantidade + quantidadeBloqueada;

    return HoldingModel(
      nomeStartup: _toText(json['nomeStartup'] ?? json['startupId']),
      setor: _toText(json['setor']),
      totalTokens: quantidadeTotal,
      valorInvestido: (quantidadeTotal * precoMedioCentavos) / 100,
      percentualRetorno: _toDouble(json['percentualRetorno']),
    );
  }
}

class TransactionModel {
  const TransactionModel({
    required this.tipo,
    required this.nomeStartup,
    required this.detalhes,
    required this.data,
    required this.valor,
  });

  final String tipo;
  final String nomeStartup;
  final String detalhes;
  final String data;
  final double valor;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final quantidade = _toDouble(json['quantidade']);

    return TransactionModel(
      tipo: _toText(json['tipo']),
      nomeStartup: _toText(json['nomeStartup'] ?? json['startupId']),
      detalhes: _buildTokenDetails(quantidade),
      data: _toText(json['createdAt']),
      valor: _toDouble(json['valorTotalCentavos']) / 100,
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    final clean = value.replaceAll('%', '').replaceAll(',', '.');
    return double.tryParse(clean) ?? 0.0;
  }
  return 0.0;
}

String _toText(dynamic value) => value == null ? '' : value.toString();

String _buildTokenDetails(double quantidade) {
  if (quantidade <= 0) return '';

  final quantidadeTexto = quantidade.toStringAsFixed(0);
  final sufixo = quantidade == 1 ? 'token' : 'tokens';
  return '$quantidadeTexto $sufixo';
}
