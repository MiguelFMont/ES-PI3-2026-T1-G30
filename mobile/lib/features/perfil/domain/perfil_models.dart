// lib/features/perfil/domain/perfil_models.dart
// Autor: Miguel Fernandes Monteiro — RA: 25014808

class PerfilModel {
  final String nome;
  final String email;
  final String telefone;
  final double saldo;
  final double patrimonio;
  final int totalStartups;
  final String desde;

  const PerfilModel({
    required this.nome,
    required this.email,
    required this.telefone,
    required this.saldo,
    required this.patrimonio,
    required this.totalStartups,
    required this.desde,
  });

  factory PerfilModel.fromJson(Map<String, dynamic> json) {
  return PerfilModel(
    nome:          json['nome']         as String? ?? 'Usuário',
    email:         json['email']        as String? ?? '',
    telefone:      json['telefone']     as String? ?? '',
    desde:         json['desde']        as String? ?? '—',
    saldo:         (json['saldo']       as num?   ?? 0).toDouble(),
    patrimonio:    (json['patrimonio']  as num?   ?? 0).toDouble(),
    totalStartups:  json['totalStartups'] as int? ?? 0,
  );
}
}