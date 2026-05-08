// Autor: Miguel Fernandes Monteiro — RA: 25014808

import '../datasource/perfil_datasource.dart';
import '../../domain/perfil_models.dart';

class PerfilRepository {
  final PerfilDatasource _datasource = PerfilDatasource();

  Future<PerfilModel> buscarPerfil() async {
    try {
      final data = await _datasource.buscarPerfil();
      return PerfilModel.fromJson(data);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
  Future<void> atualizarPerfil({
    required String nome,
    required String email,
    required String telefone,
  }) async {
    try {
      await _datasource.atualizarPerfil(
        nome: nome,
        email: email,
        telefone: telefone,
      );
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Future<void> adicionarSaldo(double amount) async {
  //   final token = await SessionManager.getToken();
  //   if (token == null) throw Exception('Sessão expirada. Faça login novamente.');

  //   final uri = Uri.parse('${AppHttpClient.baseUrl}/wallet/add-balance');

  //   final response = await http.post(
  //     uri,
  //     headers: {
  //       'Authorization': 'Bearer $token',
  //       'Content-Type': 'application/json',
  //     },
  //     body: jsonEncode({'amount': amount}),
  //   );

  //   if (response.statusCode == 200) {
  //     return;
  //   }

  //   final body =
  //       response.body.isNotEmpty ? jsonDecode(response.body) : <String, dynamic>{};
  //   throw Exception(body['message'] ?? 'Erro ao adicionar saldo');
  // }
}
