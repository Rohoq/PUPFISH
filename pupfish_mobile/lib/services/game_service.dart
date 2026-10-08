import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class GameService {
  static const String baseUrl = 'http://192.168.2.186:8000/api';

  Future<Map<String, dynamic>> getGames({
    int page = 1,
    String search = '',
  }) async {
    final token = await AuthService().getToken();

    final uri = Uri.parse('$baseUrl/games/').replace(
      queryParameters: {
        'page': page.toString(),
        if (search.isNotEmpty) 'search': search,
      },
    );

    final res = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      print('GAME API: ${res.body}');
      return jsonDecode(res.body);
    }

    throw Exception(
      'Błąd pobierania gier: ${res.statusCode}',
    );
  }

  Future<void> addToLibrary(int gameId) async {
    final token = await AuthService().getToken();

    final res = await http.post(
      Uri.parse('$baseUrl/library/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'game': gameId,
      }),
    );

    print('ADD LIBRARY: ${res.statusCode}');
    print('ADD LIBRARY BODY: ${res.body}');

    if (res.statusCode != 201) {
      throw Exception(
        'Błąd dodawania gry: ${res.statusCode} ${res.body}',
      );
    }
  }

  Future<List<dynamic>> getMyLibrary() async {
    final token = await AuthService().getToken();

    final res = await http.get(
      Uri.parse('$baseUrl/library/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('MY LIBRARY: ${res.statusCode}');
    print('MY LIBRARY BODY: ${res.body}');

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
}