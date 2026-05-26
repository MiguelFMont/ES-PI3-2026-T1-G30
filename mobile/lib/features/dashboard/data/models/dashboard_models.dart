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
    return DashboardSummaryModel(
      saldoDisponivel: _toDouble(json['saldoDisponivel']),
      valorTotalCarteira: _toDouble(json['valorTotalCarteira']),
      totalInvestido: _toDouble(json['totalInvestido']),
      lucro: _toDouble(json['lucro']),
      retorno: _toDouble(json['retorno']),
      pontosGrafico: _parseChartPoints(json['pontosGrafico']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'saldoDisponivel': saldoDisponivel,
      'valorTotalCarteira': valorTotalCarteira,
      'totalInvestido': totalInvestido,
      'lucro': lucro,
      'retorno': retorno,
      'pontosGrafico': pontosGrafico.map((point) => point.toJson()).toList(),
    };
  }

  static List<DashboardChartPointModel> _parseChartPoints(dynamic value) {
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map(
          (item) => DashboardChartPointModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}

class DashboardChartPointModel {
  const DashboardChartPointModel({
    required this.data,
    required this.valor,
  });

  final String data;
  final double valor;

  factory DashboardChartPointModel.fromJson(Map<String, dynamic> json) {
    return DashboardChartPointModel(
      data: _toText(json['data'] ?? json['createdAt']),
      valor: _toDouble(json['valor']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'valor': valor,
    };
  }
}

class HoldingModel {
  const HoldingModel({
    required this.nomeStartup,
    required this.setor,
    required this.valorInvestido,
    required this.percentualRetorno,
  });

  final String nomeStartup;
  final String setor;
  final double valorInvestido;
  final double percentualRetorno;

  factory HoldingModel.fromJson(Map<String, dynamic> json) {
    return HoldingModel(
      nomeStartup: _toText(
        json['nomeStartup'] ??
            json['startupNome'] ??
            json['nome'] ??
            json['startupId'],
      ),
      setor: _toText(json['setor'] ?? json['segmento']),
      valorInvestido: _holdingValue(json),
      percentualRetorno: _toDouble(
        json['percentualRetorno'] ??
            json['retornoPercentual'] ??
            json['retorno'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nomeStartup': nomeStartup,
      'setor': setor,
      'valorInvestido': valorInvestido,
      'percentualRetorno': percentualRetorno,
    };
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
    return TransactionModel(
      tipo: _toText(json['tipo']),
      nomeStartup: _toText(
        json['nomeStartup'] ??
            json['startupNome'] ??
            json['nome'] ??
            json['startupId'],
      ),
      detalhes: _transactionDetails(json),
      data: _toText(json['data'] ?? json['createdAt']),
      valor: _transactionValue(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'nomeStartup': nomeStartup,
      'detalhes': detalhes,
      'data': data,
      'valor': valor,
    };
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();

  if (value is String) {
    return double.tryParse(
          value.replaceAll('%', '').replaceAll(',', '.'),
        ) ??
        0.0;
  }

  return 0.0;
}

String _toText(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

double _centavosToReais(dynamic value) {
  return _toDouble(value) / 100;
}

double _holdingValue(Map<String, dynamic> json) {
  final explicitValue =
      json['valorInvestido'] ?? json['totalInvestido'] ?? json['valorDaPosicao'];
  if (explicitValue != null) return _toDouble(explicitValue);

  final explicitCents =
      json['valorInvestidoCentavos'] ??
      json['totalInvestidoCentavos'] ??
      json['valorDaPosicaoCentavos'];
  if (explicitCents != null) return _centavosToReais(explicitCents);

  final quantidade = _toDouble(json['quantidade']);
  final precoMedioCentavos = _toDouble(json['precoMedioCentavos']);
  if (quantidade > 0 && precoMedioCentavos > 0) {
    return (quantidade * precoMedioCentavos) / 100;
  }

  return 0.0;
}

double _transactionValue(Map<String, dynamic> json) {
  final explicitValue = json['valor'] ?? json['valorTotal'];
  if (explicitValue != null) return _toDouble(explicitValue);

  final explicitCents = json['valorCentavos'] ?? json['valorTotalCentavos'];
  if (explicitCents != null) return _centavosToReais(explicitCents);

  return 0.0;
}

String _transactionDetails(Map<String, dynamic> json) {
  final detalhes = _toText(json['detalhes']);
  if (detalhes.isNotEmpty) return detalhes;

  final quantidade = _toDouble(json['quantidade']);
  if (quantidade > 0) {
    return '${quantidade.toStringAsFixed(0)} tokens';
  }

  return '';
}
