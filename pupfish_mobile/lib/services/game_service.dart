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

  Future<http.Response> _authenticatedPost(
    Uri uri,
    Map<String, dynamic> body,
  ) async {
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

  Future<http.Response> _authenticatedPatch(
    Uri uri,
    Map<String, dynamic> body,
  ) async {
    final token = await _authService.getToken();
    var response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      final newToken = await _authService.refreshToken();
      if (newToken != null) {
        response = await http.patch(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
          body: jsonEncode(body),
        );
      }
    }
    return response;
  }

  Future<http.Response> _authenticatedDelete(Uri uri) async {
    final token = await _authService.getToken();
    var response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 401) {
      final newToken = await _authService.refreshToken();
      if (newToken != null) {
        response = await http.delete(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
        );
      }
    }
    return response;
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
    final res = await _authenticatedPost(Uri.parse('$baseUrl/library/'), {
      'game': gameId,
    });

    debugPrint('ADD LIBRARY: ${res.statusCode}');

    if (res.statusCode != 201) {
      throw Exception('Błąd dodawania gry: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> updateLibraryEntry(
    int entryId,
    Map<String, dynamic> changes,
  ) async {
    if (changes.isEmpty) {
      throw ArgumentError('Podaj status lub ocenę do aktualizacji.');
    }

    final response = await _authenticatedPatch(
      Uri.parse('$baseUrl/library/$entryId/'),
      changes,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Błąd aktualizacji gry: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Pobiera newsy Steam dla gry o podanym [gameId].
  ///
  /// Endpoint nie wymaga autoryzacji, ale używamy [_authenticatedGet]
  /// dla spójności (nagłówek auth jest opcjonalny po stronie serwera).
  Future<List<dynamic>> getGameNews(int gameId, {int count = 10}) async {
    final uri = Uri.parse('$baseUrl/games/$gameId/news/').replace(
      queryParameters: {'count': count.toString()},
    );

    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['news'] as List<dynamic>?) ?? [];
    }

    if (res.statusCode == 404) {
      // Gra nie ma steam_app_id — brak newsów
      return [];
    }

    throw Exception('Błąd pobierania newsów: ${res.statusCode}');
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

    throw Exception(
      'Błąd pobierania biblioteki: ${res.statusCode} ${res.body}',
    );
  }

  // --- KOMENTARZE DO GIER ---

  Future<List<dynamic>> getGameComments(int gameId) async {
    final uri = Uri.parse('$baseUrl/game-comments/').replace(
      queryParameters: {'game': gameId.toString()},
    );

    final res = await _authenticatedGet(uri);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        return data['results'];
      }
      return data is List ? data : [];
    }

    throw Exception('Błąd pobierania komentarzy: ${res.statusCode}');
  }

  Future<void> addGameComment({
    required int gameId,
    required String comment,
  }) async {
    final res = await _authenticatedPost(
      Uri.parse('$baseUrl/game-comments/'),
      {
        'game': gameId,
        'comment': comment,
      },
    );

    if (res.statusCode != 201) {
      throw Exception('Błąd dodawania komentarza: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> deleteGameComment(int commentId) async {
    final res = await _authenticatedDelete(
      Uri.parse('$baseUrl/game-comments/$commentId/'),
    );

    if (res.statusCode != 204) {
      throw Exception('Błąd usuwania komentarza: ${res.statusCode}');
    }
  }

  // --- PLATFORMY GRY ---

  Future<List<dynamic>> getGamePlatforms({int? gameId}) async {
    final uri = Uri.parse('$baseUrl/game-platforms/').replace(
      queryParameters: {
        if (gameId != null) 'game': gameId.toString(),
      },
    );
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        return data['results'];
      }
      return data is List ? data : [];
    }

    throw Exception('Błąd pobierania platform gry: ${res.statusCode}');
  }
}
