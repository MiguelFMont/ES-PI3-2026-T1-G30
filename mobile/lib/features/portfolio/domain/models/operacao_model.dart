/* 
Autora: Maria Júlia Lazarini Oleto
RA: 25006031

significado do arquivo:
modelo de transação 
representa uma transação (compra ou venda) que o usuário fez
*/

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
    this.saldoAlteriorCentavos,
    this.saldoNovoCentavos,
    required this.valorTotalCentavos,
    required this.createdAt,
  });

  // valor total em reais
  double get valorTotalReais => valorTotalCentavos / 100;

  // preco unitário em reais
  double get precoUnitarioReais =>
      precoUnitarioCentavos != null ? precoUnitarioCentavos! / 100 : 0.0;

  // verifica se é uma operação de compra ou venda
  bool get isCompra => tipo == 'COMPRA_DIRETA' || tipo == 'COMPRA_BALCAO';
  bool get isVenda => tipo == 'VENDA_DIRETA' || tipo == 'VENDA_BALCAO';

  // método factory - converte um map (JSON do Firestore) em OperacaoModel
  // ele cria uma instancia da classe (objeto dart) a partir dos dados do Firestore
  // o Firestore retorna os dados no formato de Map (Map<String, dynamic>)
  factory OperacaoModel.fromMap(String id, Map<String, dynamic> map) {
    return OperacaoModel(
      id: id,
      tipo: map['tipo'] ?? '',
      startupId: map['startupId'],
      offerId: map['offerId'],
      counterpartyUserId: map['counterpartyUserId'],
      quantidade: map['quantidade'],
      precoUnitarioCentavos: map['precoUnitarioCentavos'],
      valorTotalCentavos: (map['valorTotalCentavos'] ?? 0).toInt(),
      saldoAlteriorCentavos: map['saldoAnteriorCentavos'],
      saldoNovoCentavos: map['saldoNovoCentavos'],
      // back retorna createdAt como string ISO - data e hora
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
