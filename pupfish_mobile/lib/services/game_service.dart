import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class GameService {
  final AuthService _authService = AuthService();
  String get baseUrl => ApiConfig.baseUrl;

  Future<http.Response> _authenticatedGet(Uri uri) async {
    String? token = await _authService.getToken();
    var res = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 401) {
      final newToken = await _authService.refreshToken();
      if (newToken != null) {
        res = await http.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
        );
      }
    }
    return res;
  }

  Future<http.Response> _authenticatedPost(Uri uri, Map<String, dynamic> body) async {
    String? token = await _authService.getToken();
    var res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode == 401) {
      final newToken = await _authService.refreshToken();
      if (newToken != null) {
        res = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
          body: jsonEncode(body),
        );
      }
    }
    return res;
  }

  Future<Map<String, dynamic>> getGames({
    int page = 1,
    String search = '',
  }) async {
    final uri = Uri.parse('$baseUrl/games/').replace(
      queryParameters: {
        'page': page.toString(),
        if (search.isNotEmpty) 'search': search,
      },
    );

    final res = await _authenticatedGet(uri);

    if (res.statusCode == 200) {
      debugPrint('GAME API success');
      return jsonDecode(res.body);
    }

    throw Exception('Błąd pobierania gier: ${res.statusCode}');
  }

  Future<void> addToLibrary(int gameId) async {
    final res = await _authenticatedPost(
      Uri.parse('$baseUrl/library/'),
      {'game': gameId},
    );

    debugPrint('ADD LIBRARY: ${res.statusCode}');

    if (res.statusCode != 201) {
      throw Exception('Błąd dodawania gry: ${res.statusCode} ${res.body}');
    }
  }

  Future<List<dynamic>> getMyLibrary() async {
    final res = await _authenticatedGet(Uri.parse('$baseUrl/library/'));

    debugPrint('MY LIBRARY: ${res.statusCode}');

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        return data['results'];
      }
      return data;
    }

    throw Exception('Błąd pobierania biblioteki: ${res.statusCode} ${res.body}');
  }
}