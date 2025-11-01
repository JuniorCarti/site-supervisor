// core/services/maintenance_service.dart
import '../models/maintenance_model.dart';
import 'api_service.dart';

class MaintenanceService {
  final ApiService apiService;

  MaintenanceService(this.apiService);

  Future<MaintenanceResponse> reportMaintenance({
    required String equipmentId,
    required String equipmentName,
    required String description,
    required String base64Image,
    required String priority,
  }) async {
    try {
      final response = await apiService.post<dynamic>(
        '/api/maintenance/report',
        data: {
          'equipment_id': equipmentId,
          'equipment_name': equipmentName,
          'description': description,
          'base64_image': base64Image,
          'priority': priority,
        },
      );

      if (response.success) {
        return MaintenanceResponse.fromJson(response.data);
      } else {
        return MaintenanceResponse(
          success: false,
          message: response.error ?? 'Failed to report maintenance',
        );
      }
    } catch (e) {
      return MaintenanceResponse(
        success: false,
        message: 'Error reporting maintenance: $e',
      );
    }
  }

  Future<List<MaintenanceReport>> getMaintenanceReports() async {
    try {
      final response = await apiService.get<dynamic>('/api/maintenance');

      if (response.success) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final List<dynamic> reports = data['reports'] ?? [];
          return reports.map((report) => MaintenanceReport.fromJson(report)).toList();
        } else if (data is List) {
          return data.map((report) => MaintenanceReport.fromJson(report)).toList();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception(response.error ?? 'Failed to load maintenance reports');
      }
    } catch (e) {
      throw Exception('Error loading maintenance reports: $e');
    }
  }

  Future<MaintenanceResponse> updateMaintenanceStatus({
    required String reportId,
    required String status,
  }) async {
    try {
      final response = await apiService.patch<dynamic>(
        '/api/maintenance/$reportId',
        data: {
          'status': status,
        },
      );

      if (response.success) {
        return MaintenanceResponse.fromJson(response.data);
      } else {
        return MaintenanceResponse(
          success: false,
          message: response.error ?? 'Failed to update maintenance status',
        );
      }
    } catch (e) {
      return MaintenanceResponse(
        success: false,
        message: 'Error updating maintenance: $e',
      );
    }
  }

  Future<MaintenanceReport?> getMaintenanceReportById(String reportId) async {
    try {
      final response = await apiService.get<dynamic>('/api/maintenance/$reportId');

      if (response.success) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return MaintenanceReport.fromJson(data['report'] ?? data);
        }
        return null;
      } else {
        throw Exception(response.error ?? 'Failed to load maintenance report');
      }
    } catch (e) {
      throw Exception('Error loading maintenance report: $e');
    }
  }

  Future<MaintenanceResponse> assignSupplier({
    required String reportId,
    required String supplierId,
    required String supplierName,
    required double estimatedCost,
  }) async {
    try {
      final response = await apiService.patch<dynamic>(
        '/api/maintenance/$reportId/assign',
        data: {
          'supplier_id': supplierId,
          'supplier_name': supplierName,
          'estimated_cost': estimatedCost,
        },
      );

      if (response.success) {
        return MaintenanceResponse.fromJson(response.data);
      } else {
        return MaintenanceResponse(
          success: false,
          message: response.error ?? 'Failed to assign supplier',
        );
      }
    } catch (e) {
      return MaintenanceResponse(
        success: false,
        message: 'Error assigning supplier: $e',
      );
    }
  }

  Future<List<MaintenanceReport>> getCriticalMaintenance() async {
    try {
      final response = await apiService.get<dynamic>('/api/maintenance/critical');

      if (response.success) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final List<dynamic> reports = data['reports'] ?? [];
          return reports.map((report) => MaintenanceReport.fromJson(report)).toList();
        } else if (data is List) {
          return data.map((report) => MaintenanceReport.fromJson(report)).toList();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception(response.error ?? 'Failed to load critical maintenance');
      }
    } catch (e) {
      throw Exception('Error loading critical maintenance: $e');
    }
  }

  Future<MaintenanceResponse> completeMaintenance({
    required String reportId,
    required String notes,
    required double actualCost,
  }) async {
    try {
      final response = await apiService.patch<dynamic>(
        '/api/maintenance/$reportId/complete',
        data: {
          'notes': notes,
          'actual_cost': actualCost,
          'completed_at': DateTime.now().toIso8601String(),
        },
      );

      if (response.success) {
        return MaintenanceResponse.fromJson(response.data);
      } else {
        return MaintenanceResponse(
          success: false,
          message: response.error ?? 'Failed to complete maintenance',
        );
      }
    } catch (e) {
      return MaintenanceResponse(
        success: false,
        message: 'Error completing maintenance: $e',
      );
    }
  }
}