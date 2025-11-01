import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:site_supervisor/core/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;
  String? _token;
  Map<String, dynamic>? _user;

  AuthProvider(this._apiService);

  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if we have a stored token and validate it
      await _apiService.init();
      
      // Try to get profile to validate token
      final profileResponse = await _apiService.getProfile();
      
      if (profileResponse.success) {
        _isAuthenticated = true;
        _user = profileResponse.data;
        _error = null;
      } else {
        _isAuthenticated = false;
        await _apiService.clearToken();
      }
    } catch (e) {
      _isAuthenticated = false;
      _error = 'Failed to initialize app';
      await _apiService.clearToken();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      if (response.success) {
        // Extract token and user data from response
        final responseData = response.data;
        
        if (responseData is Map<String, dynamic>) {
          // Handle different possible response formats
          final token = responseData['token'] ?? responseData['access_token'];
          final user = responseData['user'] ?? responseData;
          
          if (token != null) {
            await _apiService.setToken(token);
            _token = token;
            _user = user is Map<String, dynamic> ? user : {'email': email};
            _isAuthenticated = true;
            _error = null;
            
            _isLoading = false;
            notifyListeners();
            return true;
          }
        }
        
        _error = 'Invalid response format';
        return false;
      } else {
        _error = response.error ?? 'Login failed';
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );

      if (response.success) {
        // After successful registration, automatically log the user in
        final loginSuccess = await login(email, password);
        
        if (!loginSuccess) {
          _error = 'Registration successful but auto-login failed';
        }
        
        return loginSuccess;
      } else {
        _error = response.error ?? 'Registration failed';
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.clearToken();
      _isAuthenticated = false;
      _token = null;
      _user = null;
      _error = null;
    } catch (e) {
      _error = 'Logout error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper method to refresh user data
  Future<void> refreshUserData() async {
    try {
      final response = await _apiService.getProfile();
      if (response.success) {
        _user = response.data;
        notifyListeners();
      }
    } catch (e) {
      // Silently fail for background refresh - only log in debug mode
      if (kDebugMode) {
        print('Failed to refresh user data: $e');
      }
    }
  }

  // Check if user has specific role
  bool hasRole(String role) {
    if (_user == null) return false;
    
    final userRole = _user!['role'];
    if (userRole is String) {
      return userRole.toLowerCase() == role.toLowerCase();
    }
    
    return false;
  }

  // Check if user is admin
  bool get isAdmin => hasRole('admin');

  // Check if user is manager
  bool get isManager => hasRole('manager') || isAdmin;

  // Check if user is driver
  bool get isDriver => hasRole('driver') || isManager || isAdmin;
}