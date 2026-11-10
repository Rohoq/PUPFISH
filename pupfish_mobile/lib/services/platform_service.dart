import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class PlatformService {
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

  // --- SŁOWNIK PLATFORM (publiczny) ---

  Future<List<dynamic>> getPlatforms() async {
    final res = await http.get(Uri.parse('$baseUrl/platforms/'));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        return data['results'];
      }
      return data is List ? data : [];
    }

    throw Exception('Błąd pobierania platform: ${res.statusCode}');
  }

  // --- PLATFORMY UŻYTKOWNIKA ---

  Future<List<dynamic>> getUserPlatforms() async {
    final res = await _authenticatedGet(Uri.parse('$baseUrl/user-platforms/'));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        return data['results'];
      }
      return data is List ? data : [];
    }

    throw Exception('Błąd pobierania platform użytkownika: ${res.statusCode}');
  }

  Future<void> addUserPlatform(int platformId) async {
    final res = await _authenticatedPost(
      Uri.parse('$baseUrl/user-platforms/'),
      {'platform': platformId},
    );

    if (res.statusCode != 201) {
      throw Exception(
        'Błąd dodawania platformy: ${res.statusCode} ${res.body}',
      );
    }
  }

  Future<void> removeUserPlatform(int entryId) async {
    final res = await _authenticatedDelete(
      Uri.parse('$baseUrl/user-platforms/$entryId/'),
    );

    if (res.statusCode != 204) {
      throw Exception('Błąd usuwania platformy: ${res.statusCode}');
    }
  }
}
