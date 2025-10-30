import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../../core/models/equipment_model.dart';

class EquipmentCard extends StatelessWidget {
  final Equipment equipment;
  final VoidCallback? onTap;

  const EquipmentCard({
    super.key,
    required this.equipment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Equipment Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getStatusColor(equipment.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getEquipmentIcon(equipment.type),
                  color: _getStatusColor(equipment.status),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Equipment Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipment.name,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      equipment.type.toUpperCase(),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getStatusColor(equipment.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getStatusText(equipment.status),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: _getStatusColor(equipment.status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Health Score
              if (equipment.healthScore != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getHealthColor(equipment.healthScore!).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${equipment.healthScore!.toInt()}%',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: _getHealthColor(equipment.healthScore!),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              
              // Navigation Arrow
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'operational':
        return AppColors.success;
      case 'maintenance':
        return AppColors.warning;
      case 'broken':
        return AppColors.error;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  Color _getHealthColor(double health) {
    if (health >= 80) return AppColors.success;
    if (health >= 60) return AppColors.primary;
    if (health >= 40) return AppColors.warning;
    return AppColors.error;
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'operational':
        return 'Operational';
      case 'maintenance':
        return 'Under Maintenance';
      case 'broken':
        return 'Broken';
      default:
        return 'Unknown';
    }
  }

  IconData _getEquipmentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'excavator':
        return Icons.explore;
      case 'bulldozer':
        return Icons.agriculture;
      case 'crane':
        return Icons.unfold_more;
      case 'truck':
        return Icons.local_shipping;
      default:
        return Icons.construction;
    }
  }
}