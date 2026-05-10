import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cross_file/cross_file.dart';

class ApiService {
  static const String baseImageUrl = 'http://localhost:8080';
  static const String baseUrl = '$baseImageUrl/api';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  ApiService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Accept'] = 'application/json';
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _storage.delete(key: 'auth_token');
          }
          return handler.next(error);
        },
      ),
    );
  }

  // ==================== AUTHENTICATION ====================
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
          'client_type': 'responder',
        },
      );
      final token = response.data['token'];
      await _storage.write(key: 'auth_token', value: token);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } finally {
      await _storage.delete(key: 'auth_token');
    }
  }

  Future<Map<String, dynamic>> getUser() async {
    final response = await _dio.get('/user');
    return response.data;
  }

  // ==================== RESPONDER INCIDENTS ====================
  Future<List<dynamic>> getIncidents({
    String? status,
    String? barangay,
    String? reporterType,
    bool assignedToMe = false, // ✅ new parameter
  }) async {
    final query = <String, dynamic>{};
    if (status != null && status != 'All') query['status'] = status;
    if (barangay != null && barangay != 'All') query['barangay'] = barangay;
    if (reporterType != null && reporterType != 'All')
      query['reporter_type'] = reporterType;
    if (assignedToMe) query['assigned_to_me'] = true; // ✅ add flag

    final response = await _dio.get(
      '/responder/incidents',
      queryParameters: query,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getIncident(int id) async {
    final response = await _dio.get('/responder/incidents/$id');
    return response.data;
  }

  Future<void> respondToIncident(int id) async {
    await _dio.post('/responder/incidents/$id/respond');
  }

  Future<void> reassignIncident(int id, String reason) async {
    await _dio.post(
      '/responder/incidents/$id/reassign',
      data: {'reason': reason},
    );
  }

  Future<void> resolveIncident(
    int id,
    int actualPersonsInvolved, {
    String? resolutionNotes,
  }) async {
    await _dio.post(
      '/responder/incidents/$id/resolve',
      data: {
        'actual_persons_involved': actualPersonsInvolved,
        'resolution_notes': resolutionNotes,
      },
    );
  }

  Future<void> addResponderNotes(int id, String notes) async {
    await _dio.post('/responder/incidents/$id/notes', data: {'notes': notes});
  }

  // ==================== PROFILE IMAGE ====================
  String? getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$baseImageUrl$normalizedPath';
  }

  Future<String> uploadProfileImage(File imageFile) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFile.path, filename: fileName),
    });
    final response = await _dio.post(
      '/user/upload-profile-image',
      data: formData,
    );
    return response.data['profile_image'] as String;
  }

  Future<File> compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: 70,
      );
      if (result == null) return file;
      return File(result.path);
    } catch (e) {
      return file;
    }
  }
}
