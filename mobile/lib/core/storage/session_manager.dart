// Autor: Miguel Fernandes Monteiro
// RA: 25014808

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SessionManager {
  static const _storage = FlutterSecureStorage();

  static const _idTokenKey = 'idToken';
  static const _refreshTokenKey = 'refreshToken';
  static const _uidKey = 'uid';
  static String get _firebaseApiKey => dotenv.env['FIREBASE_WEB_API_KEY'] ?? '';

  static Future<void> salvarSessao(
    String idToken,
    String refreshToken,
    String uid,
  ) async {
    await _storage.write(key: _idTokenKey, value: idToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _uidKey, value: uid);
  }

  static Future<String?> getToken() async {
    final token = await _storage.read(key: _idTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);

    if (token == null || refreshToken == null) return null;

    if (_tokenExpirado(token)) {
      return await renovarToken(refreshToken);
    }

    return token;
  }

  static bool _tokenExpirado(String token) {
    try {
      final parts = token.split('.');
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload['exp'] as int;
      return DateTime.now().millisecondsSinceEpoch / 1000 > exp;
    } catch (_) {
      return true;
    }
  }

  static Future<String?> renovarToken(String refreshToken) async {
    try {
      final url = Uri.parse(
        'https://securetoken.googleapis.com/v1/token?key=$_firebaseApiKey',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final novoIdToken = data['id_token'];
        final novoRefreshToken = data['refresh_token'];

        await _storage.write(key: _idTokenKey, value: novoIdToken);
        await _storage.write(key: _refreshTokenKey, value: novoRefreshToken);

        return novoIdToken;
      }
      await fazerLogout();
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> lerUid() async {
    return await _storage.read(key: _uidKey);
  }

  static Future<void> fazerLogout() async {
    await _storage.deleteAll();
  }
}
