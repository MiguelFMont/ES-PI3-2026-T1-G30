// Autor: Caio Ávila Marchi
// RA: 25008101

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mesclainvest/core/network/http_client.dart';
import '../../domain/question_model.dart';

class QuestionsDatasource {
  static const Duration _timeout = Duration(seconds: 10);

  Future<List<Question>> buscarPublicas(
    String startupId,
    String token,
  ) async {
    final uri = Uri.parse(
      '${AppHttpClient.baseUrl}/questions/$startupId/publicas',
    );
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    }).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['data'] ?? [];
      return list
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList();
    }
    throw Exception(
      'Erro ao buscar perguntas públicas: ${response.statusCode}',
    );
  }

  Future<void> enviarPergunta(
    String startupId,
    String texto,
    bool isPublica,
    String token,
  ) async {
    final uri = Uri.parse('${AppHttpClient.baseUrl}/questions/enviarPergunta');
    final response = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'startupId': startupId,
            'texto': texto,
            'isPublica': isPublica,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode != 201) {
      throw Exception('Erro ao enviar pergunta: ${response.statusCode}');
    }
  }
}
