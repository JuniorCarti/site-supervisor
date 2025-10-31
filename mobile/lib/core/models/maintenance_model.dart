class MaintenanceRecord {
  final String id;
  final String equipmentId;
  final String equipmentName;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String severity; // Add this field
  final bool isCritical;
  final bool isCompleted;
  final DateTime reportedAt;
  final DateTime createdAt; // Add this field
  final DateTime? completedAt;
  final String? assignedTo;
  final double? estimatedCost;
  final double? actualCost;
  final double? aiConfidence; // Add this field
  final List<String>? images;
  final Map<String, dynamic>? checklist;

  MaintenanceRecord({
    required this.id,
    required this.equipmentId,
    required this.equipmentName,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.severity, // Add to constructor
    this.isCritical = false,
    this.isCompleted = false,
    required this.reportedAt,
    required this.createdAt, // Add to constructor
    this.completedAt,
    this.assignedTo,
    this.estimatedCost,
    this.actualCost,
    this.aiConfidence, // Add to constructor
    this.images,
    this.checklist,
  });

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'] ?? json['_id'] ?? '',
      equipmentId: json['equipment_id'] ?? '',
      equipmentName: json['equipment_name'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'medium',
      severity: json['severity'] ?? 'medium', // Add this line
      isCritical: json['is_critical'] ?? false,
      isCompleted: json['is_completed'] ?? false,
      reportedAt: DateTime.parse(json['reported_at'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()), // Add this line
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      assignedTo: json['assigned_to'],
      estimatedCost: json['estimated_cost'] != null ? (json['estimated_cost'] as num).toDouble() : null,
      actualCost: json['actual_cost'] != null ? (json['actual_cost'] as num).toDouble() : null,
      aiConfidence: json['ai_confidence'] != null ? (json['ai_confidence'] as num).toDouble() : null, // Add this line
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      checklist: json['checklist'] is Map ? Map<String, dynamic>.from(json['checklist']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipment_id': equipmentId,
      'equipment_name': equipmentName,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'severity': severity, // Add this line
      'is_critical': isCritical,
      'is_completed': isCompleted,
      'reported_at': reportedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(), // Add this line
      'completed_at': completedAt?.toIso8601String(),
      'assigned_to': assignedTo,
      'estimated_cost': estimatedCost,
      'actual_cost': actualCost,
      'ai_confidence': aiConfidence, // Add this line
      'images': images,
      'checklist': checklist,
    };
  }
}