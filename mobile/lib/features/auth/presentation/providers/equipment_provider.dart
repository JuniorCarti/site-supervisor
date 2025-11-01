import 'package:flutter/foundation.dart';
import 'package:site_supervisor/core/services/api_service.dart';
import 'package:site_supervisor/core/services/equipment_service.dart';
import 'package:site_supervisor/core/models/equipment_model.dart';

class EquipmentProvider with ChangeNotifier {
   final EquipmentService _equipmentService = EquipmentService(ApiService());

  List<Equipment> _equipmentList = [];
  Equipment? _selectedEquipment;
  bool _isLoading = false;
  String _error = '';
  String _searchQuery = '';
  String _filterStatus = 'all';
  String _sortBy = 'name';

  EquipmentProvider(EquipmentService equipmentService);

  List<Equipment> get equipmentList => _equipmentList;
  Equipment? get selectedEquipment => _selectedEquipment;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchQuery => _searchQuery;
  String get filterStatus => _filterStatus;
  String get sortBy => _sortBy;

  // Filtered and sorted list
  List<Equipment> get filteredEquipment {
    List<Equipment> filtered = _equipmentList;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((eq) =>
        eq.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        eq.type.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (eq.model?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
        (eq.location?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }

    // Apply status filter
    if (_filterStatus != 'all') {
      filtered = filtered.where((eq) => eq.status == _filterStatus).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'name':
          return a.name.compareTo(b.name);
        case 'type':
          return a.type.compareTo(b.type);
        case 'health':
          return (b.healthScore ?? 0).compareTo(a.healthScore ?? 0);
        case 'status':
          return a.status.compareTo(b.status);
        case 'maintenance':
          final aDate = a.nextMaintenance ?? DateTime(2100);
          final bDate = b.nextMaintenance ?? DateTime(2100);
          return aDate.compareTo(bDate);
        default:
          return a.name.compareTo(b.name);
      }
    });

    return filtered;
  }

  // Special filtered lists
  List<Equipment> get criticalEquipment => 
      _equipmentList.where((eq) => eq.isCritical).toList();
  
  List<Equipment> get maintenanceRequired => 
      _equipmentList.where((eq) => eq.needsMaintenance || eq.isOverdue).toList();

  List<Equipment> get lowHealthEquipment =>
      _equipmentList.where((eq) => eq.healthScore != null && eq.healthScore! < 40).toList();

  // Statistics
  int get totalEquipment => _equipmentList.length;
  int get operationalCount => _equipmentList.where((eq) => eq.status == 'operational').length;
  int get maintenanceCount => _equipmentList.where((eq) => eq.status == 'maintenance').length;
  double get averageHealthScore {
    if (_equipmentList.isEmpty) return 0;
    final scores = _equipmentList.where((eq) => eq.healthScore != null).map((eq) => eq.healthScore!).toList();
    if (scores.isEmpty) return 0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  Future<void> loadEquipment() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _equipmentList = await _equipmentService.getEquipment();
      _error = '';
    } catch (e) {
      _error = 'Failed to load equipment: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEquipmentDetails(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedEquipment = await _equipmentService.getEquipmentById(id);
      _error = '';
    } catch (e) {
      _error = 'Failed to load equipment details: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addEquipment(Equipment equipment) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newEquipment = await _equipmentService.addEquipment(equipment);
      _equipmentList.add(newEquipment);
      _error = '';
    } catch (e) {
      _error = 'Failed to add equipment: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateEquipment(String id, Equipment equipment) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedEquipment = await _equipmentService.updateEquipment(id, equipment);
      final index = _equipmentList.indexWhere((eq) => eq.id == id);
      if (index != -1) {
        _equipmentList[index] = updatedEquipment;
      }
      if (_selectedEquipment?.id == id) {
        _selectedEquipment = updatedEquipment;
      }
      _error = '';
    } catch (e) {
      _error = 'Failed to update equipment: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteEquipment(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _equipmentService.deleteEquipment(id);
      _equipmentList.removeWhere((eq) => eq.id == id);
      if (_selectedEquipment?.id == id) {
        _selectedEquipment = null;
      }
      _error = '';
    } catch (e) {
      _error = 'Failed to delete equipment: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  void clearSelection() {
    _selectedEquipment = null;
    notifyListeners();
  }
}