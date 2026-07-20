import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_user.dart';
import 'token_storage.dart';

class AuthService {
  // Android emulator special address for your host machine's localhost.
  // If testing on a REAL phone instead, replace this with your PC's LAN IP,
  // e.g. http://192.168.1.5:5000 (must be on the same Wi-Fi network).
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  final TokenStorage _tokenStorage = TokenStorage();

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Signup failed');
    }

    await _tokenStorage.saveToken(data['token']);
    return AppUser.fromJson(data['user']);
  }

  Future<AppUser> signIn({required String email, required String password}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Login failed');
    }

    await _tokenStorage.saveToken(data['token']);
    return AppUser.fromJson(data['user']);
  }

  Future<AppUser?> getCurrentUser() async {
    final token = await _tokenStorage.getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      await _tokenStorage.clearToken();
      return null;
    }

    return AppUser.fromJson(jsonDecode(response.body));
  }

  Future<void> signOut() async {
    await _tokenStorage.clearToken();
  }

  Future<String?> getToken() => _tokenStorage.getToken();
}