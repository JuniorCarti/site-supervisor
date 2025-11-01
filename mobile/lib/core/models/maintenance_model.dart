// core/models/maintenance_model.dart
class MaintenanceReport {
  final String id;
  final String equipmentId;
  final String equipmentName;
  final String description;
  final String? imageUrl;
  final String? base64Image;
  final String status;
  final String priority;
  final String reportedBy;
  final DateTime reportedAt;
  final DateTime? completedAt;
  final String? assignedSupplier;
  final double? estimatedCost;
  final String? invoiceId;

  MaintenanceReport({
    required this.id,
    required this.equipmentId,
    required this.equipmentName,
    required this.description,
    this.imageUrl,
    this.base64Image,
    required this.status,
    required this.priority,
    required this.reportedBy,
    required this.reportedAt,
    this.completedAt,
    this.assignedSupplier,
    this.estimatedCost,
    this.invoiceId,
  });

  factory MaintenanceReport.fromJson(Map<String, dynamic> json) {
    return MaintenanceReport(
      id: json['id'] ?? '',
      equipmentId: json['equipment_id'] ?? '',
      equipmentName: json['equipment_name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'],
      base64Image: json['base64_image'],
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'medium',
      reportedBy: json['reported_by'] ?? '',
      reportedAt: DateTime.parse(json['reported_at']),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      assignedSupplier: json['assigned_supplier'],
      estimatedCost: json['estimated_cost']?.toDouble(),
      invoiceId: json['invoice_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipment_id': equipmentId,
      'equipment_name': equipmentName,
      'description': description,
      'image_url': imageUrl,
      'base64_image': base64Image,
      'status': status,
      'priority': priority,
      'reported_by': reportedBy,
      'reported_at': reportedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'assigned_supplier': assignedSupplier,
      'estimated_cost': estimatedCost,
      'invoice_id': invoiceId,
    };
  }
}

class MaintenanceResponse {
  final bool success;
  final String message;
  final MaintenanceReport? report;
  final String? invoiceId;
  final String? assignedSupplier;

  MaintenanceResponse({
    required this.success,
    required this.message,
    this.report,
    this.invoiceId,
    this.assignedSupplier,
  });

  factory MaintenanceResponse.fromJson(Map<String, dynamic> json) {
    return MaintenanceResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      report: json['report'] != null ? MaintenanceReport.fromJson(json['report']) : null,
      invoiceId: json['invoice_id'],
      assignedSupplier: json['assigned_supplier'],
    );
  }
}