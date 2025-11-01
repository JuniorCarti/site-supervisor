import 'package:flutter/material.dart';

class Equipment {
  final String id;
  final String name;
  final String type;
  final String status;
  final int health; // Added health field
  final String? model;
  final String? serialNumber;
  final double? healthScore;
  final bool isCritical;
  final DateTime? lastMaintenance;
  final DateTime? nextMaintenance;
  final String? location;
  final Map<String, dynamic>? specifications;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Equipment({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.health, // Now properly used
    this.model,
    this.serialNumber,
    this.healthScore,
    this.isCritical = false,
    this.lastMaintenance,
    this.nextMaintenance,
    this.location,
    this.specifications,
    this.createdAt,
    this.updatedAt,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? 'operational',
      health: json['health'] ?? (json['health_score'] != null ? (json['health_score'] as num).round() : 100), // Map health from JSON
      model: json['model'],
      serialNumber: json['serial_number'],
      healthScore: json['health_score'] != null ? (json['health_score'] as num).toDouble() : null,
      isCritical: json['is_critical'] ?? false,
      lastMaintenance: json['last_maintenance'] != null ? DateTime.parse(json['last_maintenance']) : null,
      nextMaintenance: json['next_maintenance'] != null ? DateTime.parse(json['next_maintenance']) : null,
      location: json['location'],
      specifications: json['specifications'] is Map ? Map<String, dynamic>.from(json['specifications']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'status': status,
      'health': health, // Include health in JSON
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

  Equipment copyWith({
    String? name,
    String? type,
    String? status,
    int? health,
    String? model,
    String? serialNumber,
    double? healthScore,
    bool? isCritical,
    DateTime? lastMaintenance,
    DateTime? nextMaintenance,
    String? location,
    Map<String, dynamic>? specifications,
  }) {
    return Equipment(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      health: health ?? this.health, // Include health in copyWith
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      healthScore: healthScore ?? this.healthScore,
      isCritical: isCritical ?? this.isCritical,
      lastMaintenance: lastMaintenance ?? this.lastMaintenance,
      nextMaintenance: nextMaintenance ?? this.nextMaintenance,
      location: location ?? this.location,
      specifications: specifications ?? this.specifications,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Update healthStatus to use health field instead of healthScore
  String get healthStatus {
    if (health >= 80) return 'Excellent';
    if (health >= 60) return 'Good';
    if (health >= 40) return 'Fair';
    return 'Poor';
  }

  // Update healthColor to use health field
  Color get healthColor {
    if (health >= 80) return Colors.green;
    if (health >= 60) return Colors.blue;
    if (health >= 40) return Colors.orange;
    return Colors.red;
  }

  bool get needsMaintenance {
    if (nextMaintenance == null) return false;
    return nextMaintenance!.isBefore(DateTime.now().add(const Duration(days: 7)));
  }

  bool get isOverdue {
    if (nextMaintenance == null) return false;
    return nextMaintenance!.isBefore(DateTime.now());
  }
}