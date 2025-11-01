// features/maintenance/presentation/providers/maintenance_provider.dart
import 'package:flutter/foundation.dart';
import 'package:site_supervisor/core/models/maintenance_model.dart';
import 'package:site_supervisor/core/services/maintenance_service.dart';

class MaintenanceProvider with ChangeNotifier {
  final MaintenanceService maintenanceService;

  MaintenanceProvider(this.maintenanceService);

  List<MaintenanceReport> _maintenanceReports = [];
  bool _isLoading = false;
  String? _error;

  List<MaintenanceReport> get maintenanceReports => _maintenanceReports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<MaintenanceReport> get pendingReports =>
      _maintenanceReports.where((report) => report.status == 'pending').toList();

  List<MaintenanceReport> get criticalReports =>
      _maintenanceReports.where((report) => report.priority == 'critical').toList();

  Future<void> loadMaintenanceReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _maintenanceReports = await maintenanceService.getMaintenanceReports();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<MaintenanceResponse> reportMaintenance({
    required String equipmentId,
    required String equipmentName,
    required String description,
    required String base64Image,
    required String priority,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await maintenanceService.reportMaintenance(
        equipmentId: equipmentId,
        equipmentName: equipmentName,
        description: description,
        base64Image: base64Image,
        priority: priority,
      );

      if (response.success && response.report != null) {
        _maintenanceReports.insert(0, response.report!);
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return MaintenanceResponse(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  Future<MaintenanceResponse> updateMaintenanceStatus({
    required String reportId,
    required String status,
  }) async {
    try {
      final response = await maintenanceService.updateMaintenanceStatus(
        reportId: reportId,
        status: status,
      );

      if (response.success) {
        // Update local list
        final index = _maintenanceReports.indexWhere((report) => report.id == reportId);
        if (index != -1) {
          _maintenanceReports[index] = _maintenanceReports[index].copyWith(status: status);
          notifyListeners();
        }
      }

      return response;
    } catch (e) {
      return MaintenanceResponse(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// Extension for copying MaintenanceReport
extension MaintenanceReportCopyWith on MaintenanceReport {
  MaintenanceReport copyWith({
    String? id,
    String? equipmentId,
    String? equipmentName,
    String? description,
    String? imageUrl,
    String? base64Image,
    String? status,
    String? priority,
    String? reportedBy,
    DateTime? reportedAt,
    DateTime? completedAt,
    String? assignedSupplier,
    double? estimatedCost,
    String? invoiceId,
  }) {
    return MaintenanceReport(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      base64Image: base64Image ?? this.base64Image,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      reportedBy: reportedBy ?? this.reportedBy,
      reportedAt: reportedAt ?? this.reportedAt,
      completedAt: completedAt ?? this.completedAt,
      assignedSupplier: assignedSupplier ?? this.assignedSupplier,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      invoiceId: invoiceId ?? this.invoiceId,
    );
  }
}