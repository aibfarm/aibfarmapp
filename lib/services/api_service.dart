import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://dashboard.aibfarm.com';

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = all http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('登录失败：${response.body}');
  }

  Future<Map<String, dynamic>> getUser(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/user'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('获取用户信息失败：${response.body}');
  }
}
