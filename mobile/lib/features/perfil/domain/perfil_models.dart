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
  final String ultimaAlteracaoSenha;

  const PerfilModel({
    required this.nome,
    required this.email,
    required this.telefone,
    required this.saldo,
    required this.desde,
    required this.cpf,
    required this.dataNascimento,
    required this.mfaAtivo,
    this.ultimaAlteracaoSenha = '—',
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
      mfaAtivo: json['mfaEnabled'] as bool? ?? false,
      ultimaAlteracaoSenha: json['ultimaAlteracaoSenha'] as String? ?? '—',
    );
  }

  PerfilModel copyWith({
    String? nome,
    String? email,
    String? telefone,
    double? saldo,
    String? desde,
    String? cpf,
    String? dataNascimento,
    bool? mfaAtivo,
    String? ultimaAlteracaoSenha,
  }) {
    return PerfilModel(
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      saldo: saldo ?? this.saldo,
      desde: desde ?? this.desde,
      cpf: cpf ?? this.cpf,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      mfaAtivo: mfaAtivo ?? this.mfaAtivo,
      ultimaAlteracaoSenha: ultimaAlteracaoSenha ?? this.ultimaAlteracaoSenha,
    );
  }
}

class WalletBalanceModel {
  final String uid;
  final int saldoCentavos;
  final String updatedAt;

  const WalletBalanceModel({
    required this.uid,
    required this.saldoCentavos,
    required this.updatedAt,
  });

  double get saldoReais => saldoCentavos / 100;

  factory WalletBalanceModel.fromJson(Map<String, dynamic> json) {
    return WalletBalanceModel(
      uid: json['uid'] as String? ?? '',
      saldoCentavos: (json['saldoCentavos'] as num? ?? 0).toInt(),
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}
