import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_user.dart';
import 'auth_service.dart';

class UserService {
  static const String baseUrl = 'http://localhost:5000/api';
  final AuthService _authService = AuthService();

  Future<AppUser> fetchUserById(String userId) async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId'),
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load user');
    }

    return AppUser.fromJson(jsonDecode(response.body));
  }

  Future<Map<String, dynamic>> toggleFollow(String userId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/follow'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to toggle follow');
    }

    return jsonDecode(response.body);
  }
}