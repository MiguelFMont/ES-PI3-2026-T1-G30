/* 
Autora: Maria Júlia Lazarini Oleto
RA: 25006031

significado do arquivo:
modelo de transação 
representa uma transação (compra ou venda) que o usuário fez
*/

import 'package:cloud_firestore/cloud_firestore.dart';

// representa uma única operação (compra ou venda) do usuário
class OperacaoModel {
  // id da operação no firestore
  final String id;
  final String tipo;
  final String? startupId;
  // id da oferta (em caso de compra e venda no mercado)
  final String? offerId;
  // id do usuário envolvido (em caso de compra e venda no mercado)
  final String? counterpartyUserId;
  final int? quantidade;
  final int? precoUnitarioCentavos;
  final int valorTotalCentavos;
  final double precoUnitarioReais;
  final double valorTotalReais;
  final int? saldoAlteriorCentavos;
  final int? saldoNovoCentavos;
  // data da operação
  final DateTime createdAt;

  const OperacaoModel({
    required this.id,
    required this.tipo,
    this.startupId,
    this.offerId,
    this.counterpartyUserId,
    this.quantidade,
    this.precoUnitarioCentavos,
    double? precoUnitarioReais,
    this.saldoAlteriorCentavos,
    this.saldoNovoCentavos,
    required this.valorTotalCentavos,
    double? valorTotalReais,
    required this.createdAt,
  }) : precoUnitarioReais =
           precoUnitarioReais ?? (precoUnitarioCentavos ?? 0) / 100,
       valorTotalReais = valorTotalReais ?? valorTotalCentavos / 100;

  // verifica se é uma operação de compra ou venda
  bool get isCompra => tipo == 'COMPRA_DIRETA' || tipo == 'COMPRA_BALCAO';
  bool get isVenda => tipo == 'VENDA_DIRETA' || tipo == 'VENDA_BALCAO';
  bool get isSaque => tipo == 'SACAR_SALDO';
  bool get isDeposito => tipo == 'ADICIONAR_SALDO';

  factory OperacaoModel.fromJson(Map<String, dynamic> json) {
    final precoUnitarioCentavos = _toNullableInt(
      json['precoUnitarioCentavos'],
    );
    final valorTotalCentavos = _toInt(json['valorTotalCentavos']);

    return OperacaoModel(
      id: _toText(json['id']),
      tipo: _toText(json['tipo']),
      startupId: _toNullableText(json['startupId']),
      offerId: _toNullableText(json['offerId']),
      counterpartyUserId: _toNullableText(json['counterpartyUserId']),
      quantidade: _toNullableInt(json['quantidade']),
      precoUnitarioCentavos: precoUnitarioCentavos,
      precoUnitarioReais: _centavosParaReais(precoUnitarioCentavos),
      valorTotalCentavos: valorTotalCentavos,
      valorTotalReais: _centavosParaReais(valorTotalCentavos),
      saldoAlteriorCentavos: _toNullableInt(json['saldoAnteriorCentavos']),
      saldoNovoCentavos: _toNullableInt(json['saldoNovoCentavos']),
      createdAt: _toDateTime(json['createdAt']),
    );
  }

  // método factory - converte um map (JSON do Firestore) em OperacaoModel
  // ele cria uma instancia da classe (objeto dart) a partir dos dados do Firestore
  // o Firestore retorna os dados no formato de Map (Map<String, dynamic>)
  factory OperacaoModel.fromMap(String id, Map<String, dynamic> map) {
    final json = Map<String, dynamic>.from(map);
    json['id'] ??= id;
    return OperacaoModel.fromJson(json);
  }
}

double _centavosParaReais(int? value) => value == null ? 0.0 : value / 100;

int _toInt(dynamic value) => _toNullableInt(value) ?? 0;

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String _toText(dynamic value) => value?.toString() ?? '';

String? _toNullableText(dynamic value) {
  final text = _toText(value).trim();
  return text.isEmpty ? null : text;
}

DateTime _toDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();

  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  if (value is Map) {
    final seconds = _toNullableInt(value['_seconds'] ?? value['seconds']);
    final nanoseconds = _toNullableInt(
          value['_nanoseconds'] ?? value['nanoseconds'],
        ) ??
        0;

    if (seconds != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000 + nanoseconds ~/ 1000000,
      );
    }
  }

  if (value is num) {
    final timestamp = value.toInt();
    final milliseconds = timestamp < 10000000000
        ? timestamp * 1000
        : timestamp;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  return DateTime.fromMillisecondsSinceEpoch(0);
}
