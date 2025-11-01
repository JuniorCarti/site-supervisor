import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:site_supervisor/features/equipment/presentation/widgets/equipment_dialog.dart';
import '../../../../core/models/equipment_model.dart';
import '../providers/equipment_provider.dart';

class EquipmentDetailsScreen extends StatelessWidget {
  final Equipment equipment;

  const EquipmentDetailsScreen({super.key, required this.equipment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(equipment.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditEquipmentDialog(context, equipment),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(context),
            const SizedBox(height: 24),
            _buildHealthSection(context),
            const SizedBox(height: 24),
            _buildDetailsSection(context),
            const SizedBox(height: 24),
            _buildMaintenanceSection(context),
            if (equipment.specifications != null && equipment.specifications!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSpecificationsSection(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _getStatusColor(equipment.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getEquipmentIcon(equipment.type),
                color: _getStatusColor(equipment.status),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    equipment.type,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(equipment.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          equipment.status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(equipment.status),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (equipment.isCritical) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'CRITICAL',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (equipment.healthScore != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${equipment.healthScore!.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: equipment.healthColor,
                          ),
                        ),
                        Text(
                          equipment.healthStatus,
                          style: TextStyle(
                            color: equipment.healthColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: LinearProgressIndicator(
                      value: equipment.healthScore! / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(equipment.healthColor),
                      borderRadius: BorderRadius.circular(8),
                      minHeight: 12,
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Text(
                'No health data available',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Equipment Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Model', equipment.model ?? 'Not specified'),
            _buildDetailRow('Serial Number', equipment.serialNumber ?? 'Not specified'),
            _buildDetailRow('Location', equipment.location ?? 'Not specified'),
            if (equipment.createdAt != null)
              _buildDetailRow('Added', _formatDate(equipment.createdAt!)),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maintenance Schedule',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMaintenanceRow(
              'Last Maintenance',
              equipment.lastMaintenance != null ? _formatDate(equipment.lastMaintenance!) : 'Never',
              Icons.history,
            ),
            _buildMaintenanceRow(
              'Next Maintenance',
              equipment.nextMaintenance != null ? _formatDate(equipment.nextMaintenance!) : 'Not scheduled',
              Icons.schedule,
            ),
            if (equipment.nextMaintenance != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: equipment.isOverdue
                      ? Colors.red.withOpacity(0.1)
                      : equipment.needsMaintenance
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      equipment.isOverdue
                          ? Icons.warning
                          : equipment.needsMaintenance
                              ? Icons.info
                              : Icons.check_circle,
                      color: equipment.isOverdue
                          ? Colors.red
                          : equipment.needsMaintenance
                              ? Colors.orange
                              : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        equipment.isOverdue
                            ? 'Maintenance is overdue!'
                            : equipment.needsMaintenance
                                ? 'Maintenance due soon'
                                : 'Maintenance on schedule',
                        style: TextStyle(
                          color: equipment.isOverdue
                              ? Colors.red
                              : equipment.needsMaintenance
                                  ? Colors.orange
                                  : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificationsSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Specifications',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...equipment.specifications!.entries.map((entry) {
              return _buildDetailRow(
                entry.key.replaceAll('_', ' ').toUpperCase(),
                entry.value.toString(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'operational':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      case 'out-of-service':
        return Colors.red;
      case 'reserved':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getEquipmentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'excavator':
        return Icons.construction;
      case 'bulldozer':
        return Icons.agriculture;
      case 'crane':
        return Icons.height;
      case 'loader':
        return Icons.local_shipping;
      case 'truck':
        return Icons.local_shipping;
      case 'generator':
        return Icons.bolt;
      case 'compressor':
        return Icons.air;
      default:
        return Icons.build;
    }
  }

  void _showEditEquipmentDialog(BuildContext context, Equipment equipment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EquipmentDialog(
        equipment: equipment,
        onSave: (updatedEquipment) {
          context.read<EquipmentProvider>().updateEquipment(equipment.id, updatedEquipment);
          Navigator.pop(context);
        },
      ),
    );
  }
}