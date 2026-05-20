import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/http_client.dart';
import '../domain/startup_model.dart';
import 'startup_mock.dart';

class StartupService {
  Future<List<Startup>> listarStartups({String? estagio}) async {
    if (kUseMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (estagio == null || estagio.isEmpty) return List.of(mockStartups);
      return mockStartups.where((s) => s.estagio == estagio).toList();
    }

    final url = Uri.parse('${AppHttpClient.baseUrl}/startups').replace(
      queryParameters:
          estagio != null && estagio.isNotEmpty ? {'estagio': estagio} : null,
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] as List<dynamic>;
        return data
            .map((json) => Startup.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw StartupApiException(
        'Erro ao buscar startups: ${response.statusCode}',
        response.statusCode,
      );
    } on StartupApiException {
      rethrow;
    } catch (_) {
      throw StartupApiException(
        'Erro de conexao com o servidor. Verifique sua internet.',
      );
    }
  }
}

class StartupApiException implements Exception {
  final String message;
  final int? statusCode;

  StartupApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'StartupApiException: $message (Status: $statusCode)';
}
