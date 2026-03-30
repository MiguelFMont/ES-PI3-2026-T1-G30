// Author: Miguel Fernandes Monteiro
// RA: 25014808

class UserModel {
  final String id;
  final String nomeCompleto;
  final String email;
  final String cpf;
  final String telefone;

  UserModel({
    required this.id,
    required this.nomeCompleto,
    required this.email,
    required this.cpf,
    required this.telefone,
  });

  // Converte o JSON da API para um UserModel
  // Equivalente a um construtor que recebe um objeto JS
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      nomeCompleto: json['nomeCompleto'],
      email: json['email'],
      cpf: json['cpf'],
      telefone: json['telefone'],
    );
  }

  // Converte o UserModel para JSON para enviar à API
  // Equivalente ao JSON.stringify() no JavaScript
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomeCompleto': nomeCompleto,
      'email': email,
      'cpf': cpf,
      'telefone': telefone,
    };
  }
}