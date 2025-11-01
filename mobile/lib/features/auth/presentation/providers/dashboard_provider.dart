import 'package:flutter/material.dart';
import 'package:site_supervisor/core/models/user_model.dart';
import 'package:site_supervisor/core/models/equipment_model.dart';
import 'package:site_supervisor/core/models/maintenance_model.dart';
import 'package:site_supervisor/core/services/api_service.dart';

class DashboardProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  User? _currentUser;
  List<Equipment> _equipment = [];
  List<MaintenanceReport> _maintenanceReports = []; // Changed from MaintenanceRecord to MaintenanceReport
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  List<Equipment> get equipment => _equipment;
  List<MaintenanceReport> get maintenanceReports => _maintenanceReports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed properties
  int get totalEquipment => _equipment.length;
  int get operationalEquipment => _equipment.where((e) => e.status == 'operational').length;
  int get maintenanceEquipment => _equipment.where((e) => e.status == 'maintenance').length;
  int get criticalEquipment => _equipment.where((e) => e.isCritical).length;
  
  List<MaintenanceReport> get criticalMaintenance => 
      _maintenanceReports.where((m) => m.priority == 'critical' && m.status != 'completed').toList();
  
  List<Equipment> get recentEquipment => 
      _equipment.take(5).toList();
  
  List<MaintenanceReport> get recentMaintenance => 
      _maintenanceReports.take(5).toList();
  
  double get averageHealth {
    if (_equipment.isEmpty) return 0.0;
    final totalHealth = _equipment.fold(0.0, (sum, equipment) => sum + equipment.health); // Using health field
    return totalHealth / _equipment.length;
  }

  // Get pending maintenance count
  int get pendingMaintenanceCount => 
      _maintenanceReports.where((m) => m.status == 'pending').length;

  // Get in-progress maintenance count
  int get inProgressMaintenanceCount => 
      _maintenanceReports.where((m) => m.status == 'in-progress').length;

  // Get completed maintenance count
  int get completedMaintenanceCount => 
      _maintenanceReports.where((m) => m.status == 'completed').length;

  // Get maintenance by priority
  int getCriticalMaintenanceCount(String priority) => 
      _maintenanceReports.where((m) => m.priority == priority).length;

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

      // Load maintenance reports
      final maintenanceResponse = await _apiService.get<List<dynamic>>('/api/maintenance');
      if (maintenanceResponse.success && maintenanceResponse.data != null) {
        _maintenanceReports = maintenanceResponse.data!
            .map((m) => MaintenanceReport.fromJson(m as Map<String, dynamic>))
            .toList();
      }

    } catch (e) {
      _error = 'Failed to load dashboard data: $e';
      if (_error!.contains('401') || _error!.contains('Authentication')) {
        _error = 'Authentication failed. Please login again.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh specific data
  Future<void> refreshEquipment() async {
    try {
      final equipmentResponse = await _apiService.get<List<dynamic>>('/api/equipment');
      if (equipmentResponse.success && equipmentResponse.data != null) {
        _equipment = equipmentResponse.data!
            .map((e) => Equipment.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to refresh equipment: $e';
      notifyListeners();
    }
  }

  Future<void> refreshMaintenance() async {
    try {
      final maintenanceResponse = await _apiService.get<List<dynamic>>('/api/maintenance');
      if (maintenanceResponse.success && maintenanceResponse.data != null) {
        _maintenanceReports = maintenanceResponse.data!
            .map((m) => MaintenanceReport.fromJson(m as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to refresh maintenance: $e';
      notifyListeners();
    }
  }

  // Add new equipment
  Future<bool> addEquipment(Equipment newEquipment) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/equipment',
        data: newEquipment.toJson(),
      );

      if (response.success) {
        _equipment.insert(0, newEquipment);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to add equipment: $e';
      notifyListeners();
      return false;
    }
  }

  // Update equipment
  Future<bool> updateEquipment(Equipment updatedEquipment) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        '/api/equipment/${updatedEquipment.id}',
        data: updatedEquipment.toJson(),
      );

      if (response.success) {
        final index = _equipment.indexWhere((e) => e.id == updatedEquipment.id);
        if (index != -1) {
          _equipment[index] = updatedEquipment;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to update equipment: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete equipment
  Future<bool> deleteEquipment(String equipmentId) async {
    try {
      final response = await _apiService.delete<dynamic>('/api/equipment/$equipmentId');

      if (response.success) {
        _equipment.removeWhere((e) => e.id == equipmentId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to delete equipment: $e';
      notifyListeners();
      return false;
    }
  }

  // Get equipment health statistics
  Map<String, int> getEquipmentHealthStats() {
    final stats = {
      'excellent': 0,
      'good': 0,
      'fair': 0,
      'poor': 0,
    };

    for (final equipment in _equipment) {
      if (equipment.health >= 80) {
        stats['excellent'] = stats['excellent']! + 1;
      } else if (equipment.health >= 60) {
        stats['good'] = stats['good']! + 1;
      } else if (equipment.health >= 40) {
        stats['fair'] = stats['fair']! + 1;
      } else {
        stats['poor'] = stats['poor']! + 1;
      }
    }

    return stats;
  }

  // Get maintenance statistics
  Map<String, int> getMaintenanceStats() {
    return {
      'pending': pendingMaintenanceCount,
      'in-progress': inProgressMaintenanceCount,
      'completed': completedMaintenanceCount,
      'critical': getCriticalMaintenanceCount('critical'),
      'high': getCriticalMaintenanceCount('high'),
      'medium': getCriticalMaintenanceCount('medium'),
      'low': getCriticalMaintenanceCount('low'),
    };
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}