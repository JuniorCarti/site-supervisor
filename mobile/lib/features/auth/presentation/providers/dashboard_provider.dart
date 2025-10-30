import 'package:flutter/material.dart';
import 'package:site_supervisor/core/models/user_model.dart';
import 'package:site_supervisor/core/models/equipment_model.dart';
import 'package:site_supervisor/core/models/maintenance_model.dart';
import 'package:site_supervisor/core/services/api_service.dart';

class DashboardProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  User? _currentUser;
  List<Equipment> _equipment = [];
  List<MaintenanceRecord> _maintenanceRecords = [];
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  List<Equipment> get equipment => _equipment;
  List<MaintenanceRecord> get maintenanceRecords => _maintenanceRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed properties
  int get totalEquipment => _equipment.length;
  int get operationalEquipment => _equipment.where((e) => e.status == 'operational').length;
  int get maintenanceEquipment => _equipment.where((e) => e.status == 'maintenance').length;
  int get criticalEquipment => _equipment.where((e) => e.isCritical).length;
  
  List<MaintenanceRecord> get criticalMaintenance => 
      _maintenanceRecords.where((m) => m.isCritical && !m.isCompleted).toList();
  
  List<Equipment> get recentEquipment => 
      _equipment.take(5).toList(); // Show latest 5 equipment
  
  double get averageHealth {
    if (_equipment.isEmpty) return 0.0;
    final totalHealth = _equipment.fold(0.0, (sum, equipment) => sum + (equipment.healthScore ?? 0.0));
    return totalHealth / _equipment.length;
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load user profile
      final userResponse = await _apiService.get<Map<String, dynamic>>('/api/auth/profile');
      if (userResponse.success && userResponse.data != null) {
        _currentUser = User.fromJson(userResponse.data!);
      }

      // Load equipment
      final equipmentResponse = await _apiService.get<List<dynamic>>('/api/equipment');
      if (equipmentResponse.success && equipmentResponse.data != null) {
        _equipment = equipmentResponse.data!
            .map((e) => Equipment.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Load maintenance records
      final maintenanceResponse = await _apiService.get<List<dynamic>>('/api/maintenance');
      if (maintenanceResponse.success && maintenanceResponse.data != null) {
        _maintenanceRecords = maintenanceResponse.data!
            .map((m) => MaintenanceRecord.fromJson(m as Map<String, dynamic>))
            .toList();
      }

    } catch (e) {
      _error = 'Failed to load dashboard data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}