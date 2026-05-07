//autor: Miguel Fernandes Monteiro
//RA: 25014808

// arquivo criado para processar os dados das chamadas http da pasta datasource

import '../datasource/auth_datasource.dart';
import '../../domain/models/user_model.dart';
import '../../../../core/storage/session_manager.dart';

class AuthRepository {
  final AuthDatasource _datasource = AuthDatasource();

  Future<void> iniciarCadastro(
    String dataNascimento,
    String nomeCompleto,
    String email,
    String cpf,
    String telefone,
    String senha,
  ) async {
    try {
      await _datasource.iniciarCadastro({
        'dataNascimento': dataNascimento,
        'nomeCompleto': nomeCompleto,
        'email': email,
        'cpf': cpf,
        'telefone': telefone,
        'senha': senha,
      });
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 2. CONCLUIR CADASTRO
  Future<void> concluirCadastro(String email, String token, String senha) async {
    try {
      await _datasource.concluirCadastro(email, token, senha);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Login — converte o Map bruto do datasource para UserModel
  Future<UserModel> login(String email, String password) async {
    try {
      final data = await _datasource.login(email, password);
      final user = UserModel.fromJson(data);

      if (user.idToken != null && user.refreshToken != null) {
        await SessionManager.salvarSessao(
          user.idToken!,
          user.refreshToken!,
          user.id,
        );
      }

      return user;
    } catch (e) {
      throw Exception('Erro ao realizar login: $e');
    }
  }

  // Solicitar Código de Recuperação
  Future<String> solicitarCodigoRecuperacao(String email) async {
    try {
      final data = await _datasource.solicitarCodigoRecuperacao(email);
      // Retorna a mensagem de sucesso que veio da API ("Se o e-mail existir...")
      return data['message'] ?? 'Código solicitado com sucesso.';
    } catch (e) {
      // O replaceAll limpa o texto 'Exception: ' que o Dart adiciona
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Redefinir a Senha
  Future<String> redefinirSenha(
    String email,
    String token,
    String novaSenha,
  ) async {
    try {
      final data = await _datasource.redefinirSenha(email, token, novaSenha);
      return data['message'] ?? 'Senha alterada com sucesso.';
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Validar Token
  Future<String> validarToken(String email, String token) async {
    try {
      final data = await _datasource.validarToken(email, token);
      return data['message'] ?? 'Código validado com sucesso.';
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> reenviarTokenCadastro(String email) async {
    try {
      await _datasource.reenviarTokenCadastro(email);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
