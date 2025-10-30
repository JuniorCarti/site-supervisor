import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String baseUrl = 'http://127.0.0.1:5000';
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

    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        if (kDebugMode) {
          print('🚀 ${options.method} ${options.uri}');
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
          print('❌ ${e.response?.statusCode} ${e.requestOptions.uri}');
          print('Error: ${e.message}');
        }
        return handler.next(e);
      },
    ));
  }

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

  // Generic API methods
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

  // ========== AUTH ENDPOINTS ==========
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

  // ========== MAINTENANCE ENDPOINTS ==========
  Future<ApiResponse<dynamic>> reportMaintenance({
    required String title,
    required String description,
    required String vehicleId,
    required String priority,
  }) async {
    return post<dynamic>('/api/maintenance/report', data: {
      'title': title,
      'description': description,
      'vehicle_id': vehicleId,
      'priority': priority,
    });
  }

  Future<ApiResponse<List<dynamic>>> getMaintenanceReports() async {
    return get<List<dynamic>>('/api/maintenance');
  }

  Future<ApiResponse<dynamic>> updateMaintenanceStatus({
    required String id,
    required String status,
  }) async {
    return patch<dynamic>('/api/maintenance/$id', data: {
      'status': status,
    });
  }

  // ========== SUPPLIER ENDPOINTS ==========
  Future<ApiResponse<dynamic>> addSupplier({
    required String name,
    required String contact,
    required String service,
    required double bid,
  }) async {
    return post<dynamic>('/api/suppliers', data: {
      'name': name,
      'contact': contact,
      'service': service,
      'bid': bid,
    });
  }

  Future<ApiResponse<List<dynamic>>> getSuppliers() async {
    return get<List<dynamic>>('/api/suppliers');
  }

  Future<ApiResponse<dynamic>> updateSupplier({
    required String id,
    double? rating,
    double? bid,
  }) async {
    return patch<dynamic>('/api/suppliers/$id', data: {
      if (rating != null) 'rating': rating,
      if (bid != null) 'bid': bid,
    });
  }

  Future<ApiResponse<dynamic>> getLowestBidSupplier() async {
    return get<dynamic>('/api/suppliers/lowest-bid');
  }

  // ========== FINANCE ENDPOINTS ==========
  Future<ApiResponse<dynamic>> createInvoice({
    required String title,
    required double amount,
    required String supplierId,
    required String description,
  }) async {
    return post<dynamic>('/api/finance/invoices', data: {
      'title': title,
      'amount': amount,
      'supplier_id': supplierId,
      'description': description,
    });
  }

  Future<ApiResponse<List<dynamic>>> getInvoices() async {
    return get<List<dynamic>>('/api/finance/invoices');
  }

  Future<ApiResponse<dynamic>> updateInvoiceStatus({
    required String id,
    required String status,
  }) async {
    return patch<dynamic>('/api/finance/invoices/$id', data: {
      'status': status,
    });
  }

  // ========== PROJECT ENDPOINTS ==========
  Future<ApiResponse<dynamic>> createProject({
    required String name,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required double budget,
  }) async {
    return post<dynamic>('/api/projects', data: {
      'name': name,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'budget': budget,
    });
  }

  Future<ApiResponse<List<dynamic>>> getProjects() async {
    return get<List<dynamic>>('/api/projects');
  }

  Future<ApiResponse<dynamic>> updateProject({
    required String id,
    String? status,
    double? forecast,
  }) async {
    return patch<dynamic>('/api/projects/$id', data: {
      if (status != null) 'status': status,
      if (forecast != null) 'forecast': forecast,
    });
  }

  // ========== AI AGENTS ENDPOINTS ==========
  Future<ApiResponse<dynamic>> sentinelAgent({
    required double temperature,
    required double oilPressure,
    required double vibration,
  }) async {
    return post<dynamic>('/api/ai/sentinel', data: {
      'temperature': temperature,
      'oil_pressure': oilPressure,
      'vibration': vibration,
    });
  }

  Future<ApiResponse<dynamic>> quartermasterAgent() async {
    return get<dynamic>('/api/ai/quartermaster');
  }

  Future<ApiResponse<dynamic>> chancellorAgent() async {
    return get<dynamic>('/api/ai/chancellor');
  }

  Future<ApiResponse<dynamic>> foremanAgent() async {
    return get<dynamic>('/api/ai/foreman');
  }

  // ========== NOTIFICATION ENDPOINTS ==========
  Future<ApiResponse<dynamic>> testNotification({
    required String channel,
    required String recipient,
    required String subject,
    required String message,
  }) async {
    return post<dynamic>('/api/notify/test', data: {
      'channel': channel,
      'recipient': recipient,
      'subject': subject,
      'message': message,
    });
  }

  // Response handling
  ApiResponse<T> _handleResponse<T>(Response response) {
    final data = response.data;
    
    if (data is Map<String, dynamic>) {
      if (data['success'] == true || response.statusCode == 200 || response.statusCode == 201) {
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
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        return ApiResponse<T>(
          success: false,
          error: data['error'] ?? data['message'] ?? e.message,
        );
      }
    }
    
    return ApiResponse<T>(
      success: false,
      error: e.message ?? 'Network error occurred',
    );
  }
}

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