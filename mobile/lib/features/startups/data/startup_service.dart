import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../domain/startup_model.dart';
import 'startup_mock.dart';

class StartupService {
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/v1';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/v1';
    } else {
      return 'http://127.0.0.1:3000/v1';
    }
  }

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
        'Erro de conexao com o servidor. Verifique sua internet.',
      );
    }
  }

  Future<Startup> buscarStartupPorId(String startupId) async {
    if (kUseMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return mockStartups.firstWhere(
        (startup) => startup.id == startupId,
        orElse: () => throw StartupApiException(
          'Startup nao encontrada.',
          404,
        ),
      );
    }

    final url = Uri.parse('$_baseUrl/startups/$startupId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return Startup.fromJson(body['data']);
      } else if (response.statusCode == 404) {
        throw StartupApiException('Startup nao encontrada.', 404);
      } else {
        throw StartupApiException(
          'Erro ao buscar startup: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is StartupApiException) {
        rethrow;
      }
      throw StartupApiException(
        'Erro de conexao com o servidor. Verifique sua internet.',
      );
    }
  }

  Future<bool> investirStartup(String startupId, double valorAInvestir) async {
    if (startupId.trim().isEmpty || valorAInvestir.isNaN) {
      return false;
    }

    await Future.delayed(const Duration(seconds: 2));
    return true;
  }
}

class StartupApiException implements Exception {
  final String message;
  final int? statusCode;

  StartupApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'StartupApiException: $message (Status: $statusCode)';
}
