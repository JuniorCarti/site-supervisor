class Equipment {
  final String id;
  final String name;
  final String type;
  final String status;
  final String? model;
  final String? serialNumber;
  final double? healthScore;
  final bool isCritical;
  final DateTime? lastMaintenance;
  final DateTime? nextMaintenance;
  final String? location;
  final Map<String, dynamic>? specifications;

  Equipment({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.model,
    this.serialNumber,
    this.healthScore,
    this.isCritical = false,
    this.lastMaintenance,
    this.nextMaintenance,
    this.location,
    this.specifications,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? 'operational',
      model: json['model'],
      serialNumber: json['serial_number'],
      healthScore: json['health_score'] != null ? (json['health_score'] as num).toDouble() : null,
      isCritical: json['is_critical'] ?? false,
      lastMaintenance: json['last_maintenance'] != null ? DateTime.parse(json['last_maintenance']) : null,
      nextMaintenance: json['next_maintenance'] != null ? DateTime.parse(json['next_maintenance']) : null,
      location: json['location'],
      specifications: json['specifications'] is Map ? Map<String, dynamic>.from(json['specifications']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'status': status,
      'model': model,
      'serial_number': serialNumber,
      'health_score': healthScore,
      'is_critical': isCritical,
      'last_maintenance': lastMaintenance?.toIso8601String(),
      'next_maintenance': nextMaintenance?.toIso8601String(),
      'location': location,
      'specifications': specifications,
    };
  }
}