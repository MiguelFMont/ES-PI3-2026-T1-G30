// Author: Miguel Fernandes Monteiro
// RA: 25014808

class UserModel {
  final String id;
  final String dataNascimento;
  final String nomeCompleto;
  final String email;
  final String cpf;
  final String telefone;
  final String? idToken;
  final String? refreshToken;
  final bool mfaRequired;
  final String? tempToken;

  UserModel({
    required this.id,
    required this.dataNascimento,
    required this.nomeCompleto,
    required this.email,
    required this.cpf,
    required this.telefone,
    this.idToken,
    this.refreshToken,
    this.mfaRequired = false,
    this.tempToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;

    // Se o backend indicou MFA obrigatório, cria um model parcial
    if (data['mfaRequired'] == true) {
      return UserModel(
        id: data['uid'] as String,
        dataNascimento: '',
        nomeCompleto: '',
        email: '',
        cpf: '',
        telefone: '',
        mfaRequired: true,
        tempToken: data['tempToken'] as String,
      );
    }

    return UserModel(
      id: data['uid'],
      dataNascimento: data['dataNascimento'],
      nomeCompleto: data['nomeCompleto'],
      email: data['email'],
      cpf: data['cpf'],
      telefone: data['telefone'],
      idToken: data['idToken'],
      refreshToken: data['refreshToken'],
      mfaRequired: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': id,
      'dataNascimento': dataNascimento,
      'nomeCompleto': nomeCompleto,
      'email': email,
      'cpf': cpf,
      'telefone': telefone,
    };
  }
}