import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class GameService {
  static const String baseUrl = 'http://localhost:8000/api';

  Future<List<dynamic>> getGames() async {
    final token = await AuthService().getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/games/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }
}