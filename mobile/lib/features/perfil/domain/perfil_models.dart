// lib/features/perfil/domain/perfil_models.dart
// Autor: Miguel Fernandes Monteiro — RA: 25014808

class PerfilModel {
  final String nome;
  final String email;
  final String telefone;
  final int saldoCentavos;
  final int patrimonioCentavos;
  final int totalStartups;
  final String desde;

  const PerfilModel({
    required this.nome,
    required this.email,
    required this.telefone,
    required this.saldoCentavos,
    required this.patrimonioCentavos,
    required this.totalStartups,
    required this.desde,
  });

  double get saldo => saldoCentavos / 100;
  double get patrimonio => patrimonioCentavos / 100;

  factory PerfilModel.fromJson(Map<String, dynamic> json) {
    return PerfilModel(
      nome: json['nome'] as String? ?? 'Usuário',
      email: json['email'] as String? ?? '',
      telefone: json['telefone'] as String? ?? '',
      desde: json['desde'] as String? ?? '—',
      saldoCentavos: (json['saldoCentavos'] as num? ?? 0).toInt(),
      patrimonioCentavos: (json['patrimonioCentavos'] as num? ?? 0).toInt(),
      totalStartups: json['totalStartups'] as int? ?? 0,
    );
  }
}
