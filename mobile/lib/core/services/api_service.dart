import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String baseUrl = 'http://127.0.0.1:5000'; // Change to your live backend URL for deployment
  late Dio _dio;
  String? _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }

        if (kDebugMode) {
          print('🚀 [${options.method}] ${options.uri}');
        }

        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('✅ ${response.statusCode} ${response.requestOptions.uri}');
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        if (kDebugMode) {
          print('❌ ERROR: ${e.response?.statusCode} - ${e.message}');
          if (e.response != null) {
            print('Response data: ${e.response!.data}');
          }
        }
        return handler.next(e);
      },
    ));
  }

  // ---------- TOKEN MANAGEMENT ----------
  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // ---------- API CALL HELPERS ----------
  Future<ApiResponse<T>> get<T>(String path, {Map<String, dynamic>? query}) async {
    try {
      final response = await _dio.get(path, queryParameters: query);
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  Future<ApiResponse<T>> post<T>(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  Future<ApiResponse<T>> put<T>(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  Future<ApiResponse<T>> patch<T>(String path, {dynamic data}) async {
    try {
      final response = await _dio.patch(path, data: data);
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  Future<ApiResponse<T>> delete<T>(String path) async {
    try {
      final response = await _dio.delete(path);
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  // ---------- AUTH ENDPOINTS ----------
  Future<ApiResponse<dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    return post<dynamic>('/api/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
  }

  Future<ApiResponse<dynamic>> login({
    required String email,
    required String password,
  }) async {
    return post<dynamic>('/api/auth/login', data: {
      'email': email,
      'password': password,
    });
  }

  Future<ApiResponse<dynamic>> getProfile() async {
    return get<dynamic>('/api/auth/profile');
  }

  // ---------- HEALTH CHECK ----------
  Future<bool> testConnection() async {
    try {
      final response = await get<dynamic>('/api/health');
      return response.success;
    } catch (e) {
      if (kDebugMode) print('Connection failed: $e');
      return false;
    }
  }

  // ---------- RESPONSE HANDLERS ----------
  ApiResponse<T> _handleResponse<T>(Response response) {
    final data = response.data;

    if (data is Map<String, dynamic>) {
      if (data['success'] == true ||
          response.statusCode == 200 ||
          response.statusCode == 201) {
        return ApiResponse<T>(
          success: true,
          data: data['data'] != null ? data['data'] as T : data as T,
          message: data['message'],
        );
      } else {
        return ApiResponse<T>(
          success: false,
          error: data['error'] ?? 'Unknown error occurred',
        );
      }
    }

    return ApiResponse<T>(
      success: response.statusCode == 200 || response.statusCode == 201,
      data: data as T,
    );
  }

  ApiResponse<T> _handleError<T>(DioException e) {
    if (e.response != null && e.response!.data is Map<String, dynamic>) {
      final data = e.response!.data;
      return ApiResponse<T>(
        success: false,
        error: data['error'] ?? data['message'] ?? e.message,
      );
    }
    return ApiResponse<T>(
      success: false,
      error: e.message ?? 'Network error occurred',
    );
  }
}

// ---------- GENERIC RESPONSE CLASS ----------
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  @override
  String toString() {
    return 'ApiResponse(success: $success, data: $data, message: $message, error: $error)';
  }
}
