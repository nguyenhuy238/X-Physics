import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://localhost:3000/api',
        ),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _storage.delete(key: 'access_token');
        }
        return handler.next(error);
      },
    ));
  }

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data) async {
    final response = await _dio.post(path, data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> setAuthToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  Future<void> clear() async {
    await _storage.delete(key: 'access_token');
  }
}
