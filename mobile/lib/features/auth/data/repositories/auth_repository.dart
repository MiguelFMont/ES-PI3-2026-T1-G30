// Autor: Miguel Fernandes Monteiro
// RA: 25014808

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

  Future<void> concluirCadastro(
    String email,
    String token,
    String senha,
  ) async {
    try {
      await _datasource.concluirCadastro(email, token, senha);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<UserModel> login(String email, String password) async {
    try {
      final data = await _datasource.login(email, password);
      final user = UserModel.fromJson(data);

      // MFA pendente: não salva sessão ainda, retorna para a tela tratar
      if (user.mfaRequired) return user;

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

  // ───── MFA Challenge (segundo fator no login) ─────

  Future<void> mfaChallenge(String uid, String tempToken, String code) async {
    try {
      final data = await _datasource.mfaChallenge(uid, tempToken, code);
      final payload = data['data'] as Map<String, dynamic>;

      await SessionManager.salvarSessao(
        payload['idToken'] as String,
        payload['refreshToken'] as String,
        uid,
      );
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<String> solicitarCodigoRecuperacao(String email) async {
    try {
      final data = await _datasource.solicitarCodigoRecuperacao(email);
      return data['message'] ?? 'Código solicitado com sucesso.';
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

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

  Future<void> logout() async {
    try {
      final idToken = await SessionManager.getToken();
      if (idToken == null) throw Exception('Sessão não encontrada.');
      await _datasource.logout(idToken);
      await SessionManager.fazerLogout();
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
