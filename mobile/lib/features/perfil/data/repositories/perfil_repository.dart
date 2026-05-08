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
}