import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:badges/badges.dart' as badges;
import 'package:site_supervisor/core/models/equipment_model.dart';
import 'package:site_supervisor/features/auth/presentation/screens/equipment_details_screen.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/equipment_card.dart';
import '../../../../shared/widgets/maintenance_alert_card.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _animationController.forward();
    
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboardData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Image
          _buildBackground(screenHeight),
          
          // Content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App Bar with Notifications
              _buildAppBar(dashboardProvider),
              
              // Main Content
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: child,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Quick Stats Row
                        _buildQuickStats(dashboardProvider),
                        
                        const SizedBox(height: 24),
                        
                        // Health Overview
                        _buildHealthOverview(dashboardProvider),
                        
                        const SizedBox(height: 24),
                        
                        // Alerts & Equipment in a Row
                        _buildAlertsAndEquipment(dashboardProvider),
                        
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Floating Action Button
          _buildFloatingActionButton(),
        ],
      ),
    );
  }

  Widget _buildBackground(double screenHeight) {
    return Transform.translate(
      offset: Offset(0, -_scrollOffset * 0.3),
      child: Container(
        width: double.infinity,
        height: screenHeight + _scrollOffset,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://images.pexels.com/photos/7245366/pexels-photo-7245366.jpeg',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.2),
              BlendMode.darken,
            ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(DashboardProvider provider) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      snap: true,
      expandedHeight: 200,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.currentUser?.name ?? 'Site Manager',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your construction fleet at a glance',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        // Notifications Icon with Badge
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: badges.Badge(
            position: badges.BadgePosition.topEnd(top: -8, end: -8),
            badgeContent: Text(
              '${provider.criticalMaintenance.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            badgeStyle: const badges.BadgeStyle(
              badgeColor: AppColors.error,
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () => _showNotificationsScreen(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(DashboardProvider provider) {
    if (provider.isLoading) {
      return _buildQuickStatsShimmer();
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'Total',
            provider.totalEquipment.toString(),
            Icons.construction,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            'Operational',
            provider.operationalEquipment.toString(),
            Icons.check_circle_outline,
            AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            'Issues',
            provider.criticalEquipment.toString(),
            Icons.warning_outlined,
            AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          Text(
            title,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsShimmer() {
    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 100,
              margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHealthOverview(DashboardProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fleet Health',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getHealthColor(provider.averageHealth).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${provider.averageHealth.toInt()}%',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: _getHealthColor(provider.averageHealth),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: Row(
                children: [
                  Expanded(
                    child: SfRadialGauge(
                      axes: <RadialAxis>[
                        RadialAxis(
                          minimum: 0,
                          maximum: 100,
                          showLabels: false,
                          showTicks: false,
                          axisLineStyle: const AxisLineStyle(
                            thickness: 0.12,
                            cornerStyle: CornerStyle.bothCurve,
                            color: AppColors.outline,
                            thicknessUnit: GaugeSizeUnit.factor,
                          ),
                          pointers: <GaugePointer>[
                            RangePointer(
                              value: provider.averageHealth.toDouble(),
                              width: 0.12,
                              color: _getHealthColor(provider.averageHealth),
                              pointerOffset: 0,
                              cornerStyle: CornerStyle.bothCurve,
                              sizeUnit: GaugeSizeUnit.factor,
                            ),
                          ],
                          annotations: <GaugeAnnotation>[
                            GaugeAnnotation(
                              positionFactor: 0.1,
                              widget: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${provider.averageHealth.toInt()}%',
                                    style: AppTextStyles.headlineSmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: _getHealthColor(provider.averageHealth),
                                    ),
                                  ),
                                  Text(
                                    _getHealthStatus(provider.averageHealth),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildHealthIndicator('Excellent', AppColors.success),
                        _buildHealthIndicator('Good', AppColors.primary),
                        _buildHealthIndicator('Fair', AppColors.warning),
                        _buildHealthIndicator('Poor', AppColors.error),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIndicator(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsAndEquipment(DashboardProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Critical Alerts
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Critical Alerts',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (provider.criticalMaintenance.isNotEmpty)
                ...provider.criticalMaintenance.take(2).map((maintenance) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MaintenanceAlertCard(maintenance: maintenance),
                  );
                })
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'No critical alerts',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Recent Equipment
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.construction, color: AppColors.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Recent Equipment',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...provider.recentEquipment.take(2).map((equipment) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: EquipmentCard(
                    equipment: equipment,
                    onTap: () => _navigateToEquipmentDetails(context, equipment),
                    onEdit: () => _showEditEquipmentDialog(context, equipment),
                    onDelete: () => _showDeleteEquipmentDialog(context, equipment.id),
                    isSelected: false,
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: FloatingActionButton(
        onPressed: () {
          _showQuickActionsDialog(context);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showQuickActionsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Important fix for overflow
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8, // Prevent overflow
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Quick Actions',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              _buildQuickActionItem(
                Icons.add,
                'Add New Equipment',
                'Register new equipment to fleet',
                () {
                  Navigator.pop(context);
                  _showAddEquipmentDialog(context);
                },
              ),
              _buildQuickActionItem(
                Icons.build_outlined,
                'Report Maintenance',
                'Create maintenance request',
                () {
                  Navigator.pop(context);
                  _showReportMaintenanceDialog(context);
                },
              ),
              _buildQuickActionItem(
                Icons.assignment_outlined,
                'Create Project',
                'Start new construction project',
                () {
                  Navigator.pop(context);
                  _showCreateProjectDialog(context);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: MediaQuery.of(context).viewInsets.bottom, // Account for keyboard
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title, 
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          )
        ),
        subtitle: Text(
          subtitle, 
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          )
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showNotificationsScreen(BuildContext context) {
    // Navigate to notifications screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening Notifications')),
    );
  }

  // Navigation Methods
  void _navigateToEquipmentDetails(BuildContext context, Equipment equipment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EquipmentDetailsScreen(equipment: equipment),
      ),
    );
  }

  void _showEditEquipmentDialog(BuildContext context, Equipment equipment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editing ${equipment.name}')),
    );
  }

  void _showDeleteEquipmentDialog(BuildContext context, String equipmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Equipment'),
        content: const Text('Are you sure you want to delete this equipment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Equipment deleted')),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEquipmentDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening Add Equipment Dialog')),
    );
  }

  void _showReportMaintenanceDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening Report Maintenance Dialog')),
    );
  }

  void _showCreateProjectDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening Create Project Dialog')),
    );
  }

  Color _getHealthColor(double health) {
    if (health >= 80) return AppColors.success;
    if (health >= 60) return AppColors.primary;
    if (health >= 40) return AppColors.warning;
    return AppColors.error;
  }

  String _getHealthStatus(double health) {
    if (health >= 80) return 'Excellent';
    if (health >= 60) return 'Good';
    if (health >= 40) return 'Fair';
    return 'Needs Attention';
  }
}