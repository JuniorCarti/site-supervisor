import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/user_model.dart';

class AuthService with ChangeNotifier {
  final ApiService _api = ApiService();
  
  User? _currentUser;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  String? get error => null;

  // Initialize auth state
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // Check if token exists and validate it
    try {
      final response = await _api.get<Map<String, dynamic>>('/api/auth/profile');
      if (response.success && response.data != null) {
        _currentUser = User.fromJson(response.data!);
        _isAuthenticated = true;
      } else {
        await _api.clearToken();
      }
    } catch (e) {
      await _api.clearToken();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Login with email and password
  Future<ApiResponse<User>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.post<Map<String, dynamic>>('/api/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.success && response.data != null) {
        _currentUser = User.fromJson(response.data!['user']);
        await _api.setToken(response.data!['token']);
        _isAuthenticated = true;
        
        notifyListeners();
        return ApiResponse<User>(
          success: true,
          data: _currentUser,
          message: response.message,
        );
      } else {
        return ApiResponse<User>(
          success: false,
          error: response.error,
        );
      }
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        error: 'Login failed: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register new user
  Future<ApiResponse<User>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.post<Map<String, dynamic>>('/api/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'phone': phone,
      });

      if (response.success && response.data != null) {
        _currentUser = User.fromJson(response.data!);
        _isAuthenticated = true;
        
        notifyListeners();
        return ApiResponse<User>(
          success: true,
          data: _currentUser,
          message: response.message,
        );
      } else {
        return ApiResponse<User>(
          success: false,
          error: response.error,
        );
      }
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        error: 'Registration failed: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _api.clearToken();
    _currentUser = null;
    _isAuthenticated = false;

    _isLoading = false;
    notifyListeners();
  }

  // Update profile
  Future<ApiResponse<User>> updateProfile(Map<String, dynamic> updates) async {
    try {
      final response = await _api.put<Map<String, dynamic>>('/api/auth/profile', data: updates);

      if (response.success && response.data != null) {
        _currentUser = User.fromJson(response.data!);
        notifyListeners();
        return ApiResponse<User>(
          success: true,
          data: _currentUser,
          message: response.message,
        );
      } else {
        return ApiResponse<User>(
          success: false,
          error: response.error,
        );
      }
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        error: 'Profile update failed: $e',
      );
    }
  }

  void clearError() {}
}