import 'package:flutter/material.dart';
import '../../../../core/models/equipment_model.dart';

class EquipmentDialog extends StatefulWidget {
  final Equipment? equipment;
  final Function(Equipment) onSave;

  const EquipmentDialog({
    super.key,
    this.equipment,
    required this.onSave,
  });

  @override
  _EquipmentDialogState createState() => _EquipmentDialogState();
}

class _EquipmentDialogState extends State<EquipmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _locationController = TextEditingController();
  final _healthScoreController = TextEditingController();

  String _status = 'operational';
  bool _isCritical = false;
  DateTime? _lastMaintenance;
  DateTime? _nextMaintenance;
  int _health = 100; // Default health value

  @override
  void initState() {
    super.initState();
    if (widget.equipment != null) {
      _nameController.text = widget.equipment!.name;
      _typeController.text = widget.equipment!.type;
      _modelController.text = widget.equipment!.model ?? '';
      _serialNumberController.text = widget.equipment!.serialNumber ?? '';
      _locationController.text = widget.equipment!.location ?? '';
      _healthScoreController.text = widget.equipment!.healthScore?.toString() ?? '';
      _status = widget.equipment!.status;
      _isCritical = widget.equipment!.isCritical;
      _lastMaintenance = widget.equipment!.lastMaintenance;
      _nextMaintenance = widget.equipment!.nextMaintenance;
      _health = widget.equipment!.health; // Initialize health from existing equipment
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _modelController.dispose();
    _serialNumberController.dispose();
    _locationController.dispose();
    _healthScoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.equipment == null ? 'Add New Equipment' : 'Edit Equipment',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 500, // Limit height for scrolling
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Equipment Name *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter equipment name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _typeController,
                          decoration: const InputDecoration(
                            labelText: 'Equipment Type *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter equipment type';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _modelController,
                                decoration: const InputDecoration(
                                  labelText: 'Model',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _serialNumberController,
                                decoration: const InputDecoration(
                                  labelText: 'Serial Number',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Health Score Field (0-100)
                        TextFormField(
                          controller: _healthScoreController,
                          decoration: const InputDecoration(
                            labelText: 'Health Score (0-100)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            // Update health value when health score changes
                            if (value.isNotEmpty) {
                              final healthValue = int.tryParse(value);
                              if (healthValue != null && healthValue >= 0 && healthValue <= 100) {
                                setState(() {
                                  _health = healthValue;
                                });
                              }
                            }
                          },
                        ),
                        
                        // Health Visual Indicator
                        const SizedBox(height: 8),
                        _buildHealthIndicator(),
                        const SizedBox(height: 16),
                        
                        DropdownButtonFormField<String>(
                          value: _status,
                          items: [
                            'operational',
                            'maintenance',
                            'out-of-service',
                            'reserved',
                          ].map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(
                                status.replaceAll('-', ' ').toUpperCase(),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _status = value!;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Critical Equipment'),
                          subtitle: const Text('Mark as critical for priority monitoring'),
                          value: _isCritical,
                          onChanged: (value) {
                            setState(() {
                              _isCritical = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDateField(
                          'Last Maintenance',
                          _lastMaintenance,
                          (date) => setState(() => _lastMaintenance = date),
                        ),
                        const SizedBox(height: 16),
                        _buildDateField(
                          'Next Maintenance',
                          _nextMaintenance,
                          (date) => setState(() => _nextMaintenance = date),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveEquipment,
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthIndicator() {
    Color getHealthColor(int health) {
      if (health >= 80) return Colors.green;
      if (health >= 60) return Colors.blue;
      if (health >= 40) return Colors.orange;
      return Colors.red;
    }

    String getHealthStatus(int health) {
      if (health >= 80) return 'Excellent';
      if (health >= 60) return 'Good';
      if (health >= 40) return 'Fair';
      return 'Poor';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Health: $_health%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: getHealthColor(_health),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              getHealthStatus(_health),
              style: TextStyle(
                color: getHealthColor(_health),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: _health / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(getHealthColor(_health)),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime? date, Function(DateTime?) onDateSelected) {
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (selectedDate != null) {
          onDateSelected(selectedDate);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : 'Select date',
              style: TextStyle(
                color: date != null ? Colors.black : Colors.grey,
              ),
            ),
            Icon(
              Icons.calendar_today,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _saveEquipment() {
    if (_formKey.currentState!.validate()) {
      // Parse health score or use the health value
      final healthScore = _healthScoreController.text.isEmpty 
          ? null 
          : double.tryParse(_healthScoreController.text);
      
      // Use healthScore to set health if provided, otherwise use the slider value
      final healthValue = healthScore?.round() ?? _health;

      final equipment = Equipment(
        id: widget.equipment?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        type: _typeController.text,
        status: _status,
        health: healthValue, // Required parameter
        model: _modelController.text.isEmpty ? null : _modelController.text,
        serialNumber: _serialNumberController.text.isEmpty ? null : _serialNumberController.text,
        healthScore: healthScore,
        isCritical: _isCritical,
        lastMaintenance: _lastMaintenance,
        nextMaintenance: _nextMaintenance,
        location: _locationController.text.isEmpty ? null : _locationController.text,
        specifications: widget.equipment?.specifications,
        createdAt: widget.equipment?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSave(equipment);
      Navigator.pop(context);
    }
  }
}