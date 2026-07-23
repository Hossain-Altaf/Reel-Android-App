import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/reel.dart';
import 'auth_service.dart';
import '../models/comment.dart';

class ReelService {
  //static const String baseUrl = 'http://10.0.2.2:5000/api';
  static const String baseUrl = 'http://localhost:5000/api';
  final AuthService _authService = AuthService();

  Future<List<Reel>> fetchFeed({int page = 1, int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reels?page=$page&limit=$limit'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load feed');
    }

    final List data = jsonDecode(response.body);
    return data.map((json) => Reel.fromJson(json)).toList();
  }

  Future<List<Reel>> fetchUserReels(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reels/user/$userId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load user reels');
    }

    final List data = jsonDecode(response.body);
    return data.map((json) => Reel.fromJson(json)).toList();
  }

  Future<Reel> uploadReel({
    required File videoFile,
    required String caption,
    File? thumbnailFile,
    void Function(double progress)? onProgress,
  }) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/reels'));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['caption'] = caption;
    request.files.add(await http.MultipartFile.fromPath('video', videoFile.path));
    if (thumbnailFile != null) {
      request.files.add(await http.MultipartFile.fromPath('thumbnail', thumbnailFile.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Upload failed');
    }

    return Reel.fromJson(jsonDecode(response.body));
  }

  Future<int> toggleLike(String reelId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/reels/$reelId/like'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to toggle like');
    }

    final data = jsonDecode(response.body);
    return data['likeCount'];
  }

  Future<void> incrementView(String reelId) async {
    await http.post(Uri.parse('$baseUrl/reels/$reelId/view'));
  }

  Future<List<Comment>> fetchComments(String reelId) async {
    final response = await http.get(Uri.parse('$baseUrl/reels/$reelId/comments'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load comments');
    }

    final List data = jsonDecode(response.body);
    return data.map((json) => Comment.fromJson(json)).toList();
  }

  Future<Comment> addComment(String reelId, String text) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/reels/$reelId/comments'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to add comment');
    }

    return Comment.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteComment(String reelId, String commentId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.delete(
      Uri.parse('$baseUrl/reels/$reelId/comments/$commentId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete comment');
    }
  }

  Future<void> deleteReel(String reelId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.delete(
      Uri.parse('$baseUrl/reels/$reelId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete reel');
    }
  }

  Future<List<Reel>> fetchFollowingFeed({int page = 1, int limit = 10}) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/reels/following?page=$page&limit=$limit'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load following feed');
    }

    final List data = jsonDecode(response.body);
    return data.map((json) => Reel.fromJson(json)).toList();
  }
}