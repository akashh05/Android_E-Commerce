import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../models/item.dart';

class ApiService {
  static const String baseUrl = 'http://13.60.32.137'; // Update as needed
  final Dio _dio;

  ApiService(String token)
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {'Authorization': 'Bearer $token'},
        ));

  // ========== AUTH METHODS (http) ==========

  static Future<bool> signup(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }

    try {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Signup failed');
    } catch (_) {
      throw Exception('Signup failed: ${response.body}');
    }
  }

  static Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['access_token'] != null) {
        return data['access_token'];
      } else {
        throw Exception('Token missing in response');
      }
    }

    try {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Login failed');
    } catch (_) {
      throw Exception('Login failed: ${response.body}');
    }
  }

  static Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/request-reset-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      try {
        final data = jsonDecode(response.body);
        throw Exception(data['detail'] ?? 'Failed to send OTP');
      } catch (_) {
        throw Exception('OTP request failed: ${response.body}');
      }
    }
  }

  static Future<void> requestResetOTP(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/request-reset-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send OTP');
    }
  }

  /// ✅ Reset Password Using OTP – Correct Endpoint: /reset-password-otp
  static Future<void> resetPasswordWithOTP({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      try {
        final data = jsonDecode(response.body);
        throw Exception(data['detail'] ?? 'Password reset failed');
      } catch (_) {
        throw Exception('Password reset failed: ${response.body}');
      }
    }
  }

  // ========== IMAGE UPLOAD (Dio) ==========

  Future<String> uploadImage(File file) async {
    String filename = file.path.split('/').last;
    FormData formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: filename),
    });

    final response = await _dio.post('/upload-image', data: formData);

    if (response.statusCode == 200) {
      return response.data['image_url'];
    } else {
      throw Exception('Image upload failed: ${response.statusMessage}');
    }
  }

  // ========== ITEM OPERATIONS (Dio) ==========

  Future<List<Item>> fetchItems() async {
    final response = await _dio.get('/items');

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data['items'];
      return data.map((itemMap) => Item.fromMap(itemMap)).toList();
    } else {
      throw Exception('Failed to fetch items: ${response.statusMessage}');
    }
  }

  Future<void> createItem({
    required String name,
    required double price,
    required String description,
    String? imageUrl,
  }) async {
    final response = await _dio.post('/items', data: {
      'name': name,
      'price': price,
      'description': description,
      'image_url': imageUrl,
    });

    if (response.statusCode != 201) {
      throw Exception('Failed to create item: ${response.statusMessage}');
    }
  }

  Future<void> deleteItem(String itemId) async {
    final response = await _dio.delete('/items/$itemId');

    if (response.statusCode != 204) {
      throw Exception('Failed to delete item: ${response.statusMessage}');
    }
  }
}
