class OfferModel {
  final String offerId;
  final String startupId;
  final int quantidade;
  final int precoUnitarioCentavos;
  final int valorTotalCentavos;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? vendedorNome;

  const OfferModel({
    required this.offerId,
    required this.startupId,
    required this.quantidade,
    required this.precoUnitarioCentavos,
    required this.valorTotalCentavos,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.vendedorNome,
  });

  double get precoUnitarioReais => precoUnitarioCentavos / 100;
  double get valorTotalReais => valorTotalCentavos / 100;

  factory OfferModel.fromMap(Map<String, dynamic> map) {
    return OfferModel(
      offerId: map['offerId'] as String? ?? '',
      startupId: map['startupId'] as String? ?? '',
      quantidade: (map['quantidade'] as num? ?? 0).toInt(),
      precoUnitarioCentavos: (map['precoUnitarioCentavos'] as num? ?? 0)
          .toInt(),
      valorTotalCentavos: (map['valorTotalCentavos'] as num? ?? 0).toInt(),
      status: map['status'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String? ?? ''),
      updatedAt: DateTime.parse(map['updatedAt'] as String? ?? ''),
      vendedorNome: map['vendedorNome'] as String?,
    );
  }
}
