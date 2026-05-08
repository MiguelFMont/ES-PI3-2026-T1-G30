// lib/features/perfil/domain/perfil_models.dart
// Autor: Miguel Fernandes Monteiro — RA: 25014808

class PerfilModel {
  final String nome;
  final String email;
  final String telefone;
  final double saldo;
  final String desde;
  final String cpf;
  final String dataNascimento;
  final bool mfaAtivo;

  const PerfilModel({
    required this.nome,
    required this.email,
    required this.telefone,
    required this.saldo,
    required this.desde,
    required this.cpf,
    required this.dataNascimento,
    required this.mfaAtivo,
  });

  factory PerfilModel.fromJson(Map<String, dynamic> json) {
    return PerfilModel(
      nome: json['nome'] as String? ?? 'Usuário',
      email: json['email'] as String? ?? '',
      telefone: json['telefone'] as String? ?? '',
      desde: json['desde'] as String? ?? '—',
      saldo: (json['saldo'] as num? ?? 0).toDouble(),
      cpf: json['cpf'] as String? ?? '',
      dataNascimento: json['dataNascimento'] as String? ?? '—',
      mfaAtivo: json['mfEnabled'] as bool? ?? false,
    );
  }
}
