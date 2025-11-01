// features/maintenance/presentation/screens/report_maintenance_screen.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:site_supervisor/core/models/equipment_model.dart';
import 'package:site_supervisor/features/maintenance/presentation/providers/maintenance_provider.dart';

class ReportMaintenanceScreen extends StatefulWidget {
  const ReportMaintenanceScreen({super.key});

  @override
  State<ReportMaintenanceScreen> createState() => _ReportMaintenanceScreenState();
}

class _ReportMaintenanceScreenState extends State<ReportMaintenanceScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _equipmentController = TextEditingController();
  String _selectedPriority = 'medium';
  Equipment? _selectedEquipment;

  final List<Equipment> _equipmentList = [
    Equipment(
      id: '1',
      name: 'Excavator CAT 320',
      type: 'Heavy Equipment',
      status: 'operational',
      health: 85,
      lastMaintenance: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Equipment(
      id: '2',
      name: 'Bulldozer Komatsu',
      type: 'Heavy Equipment',
      status: 'operational',
      health: 78,
      lastMaintenance: DateTime.now().subtract(const Duration(days: 45)),
    ),
    Equipment(
      id: '3',
      name: 'Crane Terex 250T',
      type: 'Heavy Equipment',
      status: 'operational',
      health: 92,
      lastMaintenance: DateTime.now().subtract(const Duration(days: 15)),
    ),
  ];

  Future<void> _takePicture() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _submitMaintenanceReport() async {
    if (_selectedEquipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select equipment')),
      );
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a picture of the issue')),
      );
      return;
    }

    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue')),
      );
      return;
    }

    // Convert image to base64
    final imageBytes = await _selectedImage!.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final maintenanceProvider = context.read<MaintenanceProvider>();

    final response = await maintenanceProvider.reportMaintenance(
      equipmentId: _selectedEquipment!.id,
      equipmentName: _selectedEquipment!.name,
      description: _descriptionController.text,
      base64Image: base64Image,
      priority: _selectedPriority,
    );

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back or show success
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEquipmentSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Equipment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _equipmentList.length,
                itemBuilder: (context, index) {
                  final equipment = _equipmentList[index];
                  return ListTile(
                    leading: const Icon(Icons.construction),
                    title: Text(equipment.name),
                    subtitle: Text('Status: ${equipment.status}'),
                    onTap: () {
                      setState(() {
                        _selectedEquipment = equipment;
                        _equipmentController.text = equipment.name;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Maintenance Issue'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Equipment Selection
            _buildEquipmentSelection(),
            const SizedBox(height: 20),
            
            // Issue Description
            _buildDescriptionField(),
            const SizedBox(height: 20),
            
            // Priority Selection
            _buildPrioritySelection(),
            const SizedBox(height: 20),
            
            // Image Capture Section
            _buildImageCaptureSection(),
            const SizedBox(height: 30),
            
            // Submit Button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Equipment',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _equipmentController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Select equipment',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_drop_down),
              onPressed: _showEquipmentSelection,
            ),
          ),
          onTap: _showEquipmentSelection,
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Issue Description',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe the issue in detail...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedPriority,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'low', child: Text('Low Priority')),
            DropdownMenuItem(value: 'medium', child: Text('Medium Priority')),
            DropdownMenuItem(value: 'high', child: Text('High Priority')),
            DropdownMenuItem(value: 'critical', child: Text('Critical - Urgent')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedPriority = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildImageCaptureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photo Evidence',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Take a clear photo of the issue for better analysis',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        
        if (_selectedImage != null)
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: FileImage(_selectedImage!),
                fit: BoxFit.cover,
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                SizedBox(height: 8),
                Text('No image selected'),
              ],
            ),
          ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                onPressed: _takePicture,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('From Gallery'),
                onPressed: _pickFromGallery,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _submitMaintenanceReport,
        child: const Text(
          'Submit Maintenance Report',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}