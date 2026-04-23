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

  UserModel({
    required this.id,
    required this.dataNascimento,
    required this.nomeCompleto,
    required this.email,
    required this.cpf,
    required this.telefone,
    this.idToken,
    this.refreshToken,
  });

  // Converte o JSON da API para um UserModel
  // Equivalente a um construtor que recebe um objeto JS
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return UserModel(
      id: data['uid'],
      dataNascimento: data['dataNascimento'],
      nomeCompleto: data['nomeCompleto'],
      email: data['email'],
      cpf: data['cpf'],
      telefone: data['telefone'],
      idToken: data['idToken'],
      refreshToken: data['refreshToken'],
    );
  }

  // Converte o UserModel para JSON para enviar à API
  // Equivalente ao JSON.stringify() no JavaScript
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
