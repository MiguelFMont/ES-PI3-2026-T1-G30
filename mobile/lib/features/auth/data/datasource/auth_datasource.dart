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
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  //cadastro
  Future<Map<String, dynamic>> cadastro(
    String dataNascimento,
    String nomeCompleto,
    String email,
    String cpf,
    String telefone,
    String senha,
  ) async {
    final response = await http.post(
      // converte a URL para URI que é o objeto que o dart aceita
      Uri.parse('${AppHttpClient.baseUrl}/auth/register'),
      // informa ao backend que o body é JSON
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'dataNascimento': dataNascimento,
        'nomeCompleto': nomeCompleto,
        'email': email,
        'cpf': cpf,
        'telefone': telefone,
        'senha': senha,
      }),
    );
    return jsonDecode(response.body);
  }
}
