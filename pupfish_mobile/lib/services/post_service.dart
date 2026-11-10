import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class PostService {
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

  // --- POSTY ---

  Future<Map<String, dynamic>> getPosts({int? gameId, int page = 1}) async {
    final uri = Uri.parse('$baseUrl/posts/').replace(
      queryParameters: {
        'page': page.toString(),
        if (gameId != null) 'game': gameId.toString(),
      },
    );

    final res = await _authenticatedGet(uri);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    throw Exception('Błąd pobierania postów: ${res.statusCode}');
  }

  Future<void> createPost({
    required String title,
    required String content,
    required int gameId,
  }) async {
    final res = await _authenticatedPost(
      Uri.parse('$baseUrl/posts/'),
      {
        'title': title,
        'content': content,
        'game': gameId,
      },
    );

    if (res.statusCode != 201) {
      throw Exception('Błąd tworzenia posta: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> deletePost(int postId) async {
    final res = await _authenticatedDelete(
      Uri.parse('$baseUrl/posts/$postId/'),
    );

    if (res.statusCode != 204) {
      throw Exception('Błąd usuwania posta: ${res.statusCode}');
    }
  }

  // --- KOMENTARZE DO POSTÓW ---

  Future<List<dynamic>> getPostComments(int postId) async {
    final uri = Uri.parse('$baseUrl/post-comments/').replace(
      queryParameters: {'post': postId.toString()},
    );

    final res = await _authenticatedGet(uri);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        return data['results'];
      }
      return data is List ? data : [];
    }

    throw Exception('Błąd pobierania komentarzy do posta: ${res.statusCode}');
  }

  Future<void> addPostComment({
    required int postId,
    required String comment,
  }) async {
    final res = await _authenticatedPost(
      Uri.parse('$baseUrl/post-comments/'),
      {
        'post': postId,
        'comment': comment,
      },
    );

    if (res.statusCode != 201) {
      throw Exception(
        'Błąd dodawania komentarza do posta: ${res.statusCode} ${res.body}',
      );
    }
  }

  Future<void> deletePostComment(int commentId) async {
    final res = await _authenticatedDelete(
      Uri.parse('$baseUrl/post-comments/$commentId/'),
    );

    if (res.statusCode != 204) {
      throw Exception('Błąd usuwania komentarza: ${res.statusCode}');
    }
  }
}
