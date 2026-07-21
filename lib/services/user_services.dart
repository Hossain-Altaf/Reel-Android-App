import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_user.dart';

class UserService {
  static const String baseUrl = 'http://localhost:5000/api';
  // Remember: use 10.0.2.2 instead of localhost if you're on the emulator, not a phone.

  Future<AppUser> fetchUserById(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$userId'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load user');
    }

    return AppUser.fromJson(jsonDecode(response.body));
  }
}