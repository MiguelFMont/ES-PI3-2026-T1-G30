//arquivo usado somente para fazer as chamadas HTTP
// Author: Miguel
// RA: 25014808
import 'dart:convert'; // jsonEncode e jsonDecode
import 'package:http/http.dart' as http; // requisições HTTP
import '../../../../core/network/http_client.dart'; // AppHttpClient.baseUrl

class AuthDatasource {
  //login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${AppHttpClient.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Erro ao realizar login.');
    }
  }

  //cadastro
  Future<void> iniciarCadastro(Map<String, dynamic> dados) async {
    final url = Uri.parse('${AppHttpClient.baseUrl}/auth/register/iniciar');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dados),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final erro = jsonDecode(response.body);
      throw Exception(
        erro['message'] ?? 'Erro ao iniciar cadastro. Tente novamente.',
      );
    }
  }

  Future<void> concluirCadastro(String email, String token) async {
    final url = Uri.parse('${AppHttpClient.baseUrl}/auth/register/concluir');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'token': token}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final erro = jsonDecode(response.body);
      throw Exception(erro['message'] ?? 'Erro ao validar o código.');
    }
  }

  // Solicitar Código (Esqueci a senha)
  Future<Map<String, dynamic>> solicitarCodigoRecuperacao(String email) async {
    final response = await http.post(
      Uri.parse('${AppHttpClient.baseUrl}/auth/recuperar-senha'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      // Se a API retornar erro (ex: 400), jogamos a mensagem do backend para cima
      throw Exception(data['message'] ?? 'Erro ao solicitar código.');
    }
  }

  // Enviar a Nova Senha com o Token
  Future<Map<String, dynamic>> redefinirSenha(
    String email,
    String token,
    String novaSenha,
  ) async {
    final response = await http.post(
      Uri.parse('${AppHttpClient.baseUrl}/auth/redefinir-senha'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'token': token,
        'novaSenha': novaSenha,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Erro ao redefinir senha.');
    }
  }

  // Validar Token
  Future<Map<String, dynamic>> validarToken(String email, String token) async {
    final response = await http.post(
      Uri.parse('${AppHttpClient.baseUrl}/auth/validar-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'token': token}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Erro ao validar código.');
    }
  }

  Future<void> reenviarTokenCadastro(String email) async {
    final response = await http.post(
      Uri.parse('${AppHttpClient.baseUrl}/auth/register/reenviar-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Erro ao reenviar código.');
    }
  }
}
