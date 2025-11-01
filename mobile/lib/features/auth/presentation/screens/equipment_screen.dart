import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:site_supervisor/features/equipment/presentation/widgets/equipment_dialog.dart';
import '../providers/equipment_provider.dart';
import '../../../../core/models/equipment_model.dart';
import '../../../../shared/widgets/equipment_card.dart';
import '../../../../shared/widgets/animated_button.dart';
import 'equipment_details_screen.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  _EquipmentScreenState createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EquipmentProvider>().loadEquipment();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildAppBar(context),
            _buildStatsBar(),
            _buildTabBar(),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAllEquipmentTab(),
            _buildCriticalTab(),
            _buildMaintenanceTab(),
            _buildLowHealthTab(),
          ],
        ),
      ),
      floatingActionButton: AnimatedButton(
        onPressed: () => _showAddEquipmentDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      title: const Text('Equipment Management'),
      floating: true,
      snap: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
        ),
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: _showSortDialog,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<EquipmentProvider>().loadEquipment(),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search equipment...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            onChanged: (value) {
              context.read<EquipmentProvider>().setSearchQuery(value);
            },
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildStatsBar() {
    return SliverToBoxAdapter(
      child: Consumer<EquipmentProvider>(
        builder: (context, provider, child) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', provider.totalEquipment.toString(), Icons.build),
                _buildStatItem('Operational', provider.operationalCount.toString(), Icons.check_circle),
                _buildStatItem('Maintenance', provider.maintenanceCount.toString(), Icons.construction),
                _buildStatItem('Avg Health', '${provider.averageHealthScore.toStringAsFixed(0)}%', Icons.health_and_safety),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  SliverPersistentHeader _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Critical'),
            Tab(text: 'Maintenance'),
            Tab(text: 'Low Health'),
          ],
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildAllEquipmentTab() {
    return Consumer<EquipmentProvider>(
      builder: (context, provider, child) {
        return _buildEquipmentList(provider.filteredEquipment);
      },
    );
  }

  Widget _buildCriticalTab() {
    return Consumer<EquipmentProvider>(
      builder: (context, provider, child) {
        return _buildEquipmentList(provider.criticalEquipment);
      },
    );
  }

  Widget _buildMaintenanceTab() {
    return Consumer<EquipmentProvider>(
      builder: (context, provider, child) {
        return _buildEquipmentList(provider.maintenanceRequired);
      },
    );
  }

  Widget _buildLowHealthTab() {
    return Consumer<EquipmentProvider>(
      builder: (context, provider, child) {
        return _buildEquipmentList(provider.lowHealthEquipment);
      },
    );
  }

  Widget _buildEquipmentList(List<Equipment> equipmentList) {
    return Consumer<EquipmentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && equipmentList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: ${provider.error}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadEquipment(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (equipmentList.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.build, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No equipment found',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadEquipment(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: equipmentList.length,
            itemBuilder: (context, index) {
              final equipment = equipmentList[index];
              return EquipmentCard(
                equipment: equipment,
                onTap: () => _showEquipmentDetails(context, equipment),
                onEdit: () => _showEditEquipmentDialog(context, equipment),
                onDelete: () => _deleteEquipment(context, equipment.id),
              );
            },
          ),
        );
      },
    );
  }

  void _showEquipmentDetails(BuildContext context, Equipment equipment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EquipmentDetailsScreen(equipment: equipment),
      ),
    );
  }

  void _showAddEquipmentDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EquipmentDialog(
        onSave: (equipment) {
          context.read<EquipmentProvider>().addEquipment(equipment);
          Navigator.pop(context);
        },
      ),
    );
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

  void _deleteEquipment(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Equipment'),
        content: const Text('Are you sure you want to delete this equipment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<EquipmentProvider>().deleteEquipment(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final provider = context.read<EquipmentProvider>();
        return AlertDialog(
          title: const Text('Filter Equipment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...['all', 'operational', 'maintenance', 'out-of-service'].map((status) {
                return RadioListTile<String>(
                  title: Text(status.toUpperCase()),
                  value: status,
                  groupValue: provider.filterStatus,
                  onChanged: (value) {
                    provider.setFilterStatus(value!);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final provider = context.read<EquipmentProvider>();
        return AlertDialog(
          title: const Text('Sort Equipment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...[
                {'value': 'name', 'label': 'Name'},
                {'value': 'type', 'label': 'Type'},
                {'value': 'health', 'label': 'Health Score'},
                {'value': 'status', 'label': 'Status'},
                {'value': 'maintenance', 'label': 'Next Maintenance'},
              ].map((sortOption) {
                return RadioListTile<String>(
                  title: Text(sortOption['label']!),
                  value: sortOption['value']!,
                  groupValue: provider.sortBy,
                  onChanged: (value) {
                    provider.setSortBy(value!);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return oldDelegate.tabBar != tabBar;
  }
}