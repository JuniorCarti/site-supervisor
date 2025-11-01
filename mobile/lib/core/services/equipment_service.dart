import '../models/equipment_model.dart';
import 'api_service.dart';

class EquipmentService {
  final ApiService _apiService;

  EquipmentService(this._apiService);

  Future<List<Equipment>> getEquipment() async {
    final response = await _apiService.get<List<dynamic>>('/api/equipment');
    
    if (response.success && response.data != null) {
      return response.data!.map((json) => Equipment.fromJson(json)).toList();
    } else {
      throw Exception(response.error ?? 'Failed to load equipment');
    }
  }

  Future<Equipment> getEquipmentById(String id) async {
    final response = await _apiService.get<Map<String, dynamic>>('/api/equipment/$id');
    
    if (response.success && response.data != null) {
      return Equipment.fromJson(response.data!);
    } else {
      throw Exception(response.error ?? 'Failed to load equipment details');
    }
  }

  Future<Equipment> addEquipment(Equipment equipment) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/api/equipment',
      data: equipment.toJson(),
    );
    
    if (response.success && response.data != null) {
      return Equipment.fromJson(response.data!);
    } else {
      throw Exception(response.error ?? 'Failed to add equipment');
    }
  }

  Future<Equipment> updateEquipment(String id, Equipment equipment) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      '/api/equipment/$id',
      data: equipment.toJson(),
    );
    
    if (response.success && response.data != null) {
      return Equipment.fromJson(response.data!);
    } else {
      throw Exception(response.error ?? 'Failed to update equipment');
    }
  }

  Future<void> deleteEquipment(String id) async {
    final response = await _apiService.delete<dynamic>('/api/equipment/$id');
    
    if (!response.success) {
      throw Exception(response.error ?? 'Failed to delete equipment');
    }
  }

  Future<List<Equipment>> getCriticalEquipment() async {
    final allEquipment = await getEquipment();
    return allEquipment.where((eq) => eq.isCritical).toList();
  }

  Future<List<Equipment>> getMaintenanceRequired() async {
    final allEquipment = await getEquipment();
    return allEquipment.where((eq) => eq.needsMaintenance || eq.isOverdue).toList();
  }

  Future<List<Equipment>> getLowHealthEquipment() async {
    final allEquipment = await getEquipment();
    return allEquipment.where((eq) => eq.healthScore != null && eq.healthScore! < 40).toList();
  }
}