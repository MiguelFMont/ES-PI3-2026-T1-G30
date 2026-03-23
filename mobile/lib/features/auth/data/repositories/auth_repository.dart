//autor: Miguel Fernandes Monteiro
//RA: 25014808

// arquivo criado para processar os dados das chamadas http da pasta datasource

import '../datasource/auth_datasource.dart';
import '../../domain/models/user_model.dart';

class AuthRepository {
  final AuthDatasource _datasource = AuthDatasource();

  // Cadastro — converte o Map bruto do datasource para UserModel
  Future<UserModel> cadastro(
    String nomeCompleto,
    String email,
    String cpf,
    String telefone,
    String senha,
  ) async {
    try {
      final data = await _datasource.cadastro(
        nomeCompleto,
        email,
        cpf,
        telefone,
        senha,
      );
      return UserModel.fromJson(data);
    } catch (e) {
      throw Exception('Erro ao realizar cadastro: $e');
    }
  }

  // Login — converte o Map bruto do datasource para UserModel
  Future<UserModel> login(String email, String password) async {
    try {
      final data = await _datasource.login(email, password);
      return UserModel.fromJson(data);
    } catch (e) {
      throw Exception('Erro ao realizar login: $e');
    }
  }
}