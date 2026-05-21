class HoldingModel {
  final String startupId;
  final int quantidade;
  final int quantidadeBloqueada;
  final int precoMedioCentavos;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HoldingModel({
    required this.startupId,
    required this.quantidade,
    required this.quantidadeBloqueada,
    required this.precoMedioCentavos,
    required this.createdAt,
    required this.updatedAt,
  });

  double get precoMedioReais => precoMedioCentavos / 100;

  factory HoldingModel.fromMap(Map<String, dynamic> map) {
    return HoldingModel(
      startupId: map['startupId'] as String? ?? '',
      quantidade: (map['quantidade'] as num? ?? 0).toInt(),
      quantidadeBloqueada: (map['quantidadeBloqueada'] as num? ?? 0).toInt(),
      precoMedioCentavos: (map['precoMedioCentavos'] as num? ?? 0).toInt(),
      createdAt: DateTime.parse(map['createdAt'] as String? ?? ''),
      updatedAt: DateTime.parse(map['updatedAt'] as String? ?? ''),
    );
  }
}
