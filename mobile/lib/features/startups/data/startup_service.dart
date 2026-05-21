import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../domain/startup_model.dart';
import 'startup_mock.dart';

class StartupService {
  // URL base do backend
  static String get _baseUrl {
    if (kIsWeb) {
      return 'https://localhost:3000';
    } else if (Platform.isAndroid) {
      return 'https://10.0.2.2:3000'; // é para o emulador de android
    } else {
      return 'https://127.0.0.1:3000'; // para emulador de ios( provavelmente eu vou tirar isso por não ter que testar no ios)
    }
  }

  // Busca todas as startups, com filtro opcional por estágio
  Future<List<Startup>> listarStartups({String? estagio}) async {
    if (kUseMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (estagio == null || estagio.isEmpty) return List.of(mockStartups);
      return mockStartups.where((s) => s.estagio == estagio).toList();
    }

    final url = estagio != null && estagio.isNotEmpty
        ? Uri.parse('$_baseUrl/startups?estagio=$estagio')
        : Uri.parse('$_baseUrl/startups');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> data = body['data'];
        return data.map((json) => Startup.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao buscar startups: ${response.statusCode}');
      }
    } catch (e) {
      if (e is StartupApiException) {
        rethrow;
      }
      throw StartupApiException(
        'Erro de conexão com o servidor. Verifique sua internet.',
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
