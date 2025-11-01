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
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    
    _animationController.forward();
    
    // Load dashboard data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboardData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: CustomScrollView(
          slivers: [
            // App Bar
            _buildAppBar(dashboardProvider),
            
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    _buildWelcomeSection(dashboardProvider),
                    
                    const SizedBox(height: 32),
                    
                    // Statistics Grid
                    _buildStatisticsGrid(dashboardProvider),
                    
                    const SizedBox(height: 32),
                    
                    // Health Overview
                    _buildHealthOverview(dashboardProvider),
                    
                    const SizedBox(height: 32),
                    
                    // Critical Alerts
                    if (dashboardProvider.criticalMaintenance.isNotEmpty)
                      _buildCriticalAlerts(dashboardProvider),
                    
                    const SizedBox(height: 32),
                    
                    // Recent Equipment
                    _buildRecentEquipment(dashboardProvider),
                    
                    const SizedBox(height: 80), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Floating Action Button for Quick Actions
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  SliverAppBar _buildAppBar(DashboardProvider provider) {
    return SliverAppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      floating: true,
      snap: true,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.construction, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SiteSupervisor',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                'Dashboard',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        badges.Badge(
          position: badges.BadgePosition.topEnd(top: -8, end: -8),
          badgeContent: Text(
            '${provider.criticalMaintenance.length}',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          badgeStyle: const badges.BadgeStyle(
            badgeColor: AppColors.error,
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications
            },
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.outline),
          ),
          child: ClipOval(
            child: _buildUserAvatar(provider),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildUserAvatar(DashboardProvider provider) {
    final currentUser = provider.currentUser;
    
    if (currentUser?.avatar != null && currentUser!.avatar!.isNotEmpty) {
      return Image.network(
        currentUser.avatar!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person_outline, size: 20);
        },
      );
    } else {
      return const Icon(Icons.person_outline, size: 20);
    }
  }

  Widget _buildWelcomeSection(DashboardProvider provider) {
    final userName = provider.currentUser?.name ?? 'Site Manager';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good ${_getTimeOfDay()},',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          userName,
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Here\'s your fleet overview',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsGrid(DashboardProvider provider) {
    if (provider.isLoading) {
      return _buildStatisticsShimmer();
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        StatCard(
          title: 'Total Equipment',
          value: provider.totalEquipment.toString(),
          subtitle: 'Active fleet',
          icon: Icons.construction,
          color: AppColors.primary,
          gradient: AppColors.primaryGradient,
        ),
        StatCard(
          title: 'Operational',
          value: provider.operationalEquipment.toString(),
          subtitle: 'Ready to work',
          icon: Icons.check_circle_outline,
          color: AppColors.success,
          gradient: AppColors.successGradient,
        ),
        StatCard(
          title: 'Maintenance',
          value: provider.maintenanceEquipment.toString(),
          subtitle: 'Needs attention',
          icon: Icons.build_outlined,
          color: AppColors.warning,
          gradient: AppColors.warningGradient,
        ),
        StatCard(
          title: 'Critical',
          value: provider.criticalEquipment.toString(),
          subtitle: 'Urgent issues',
          icon: Icons.warning_outlined,
          color: AppColors.error,
          gradient: AppColors.errorGradient,
        ),
      ],
    );
  }

  Widget _buildStatisticsShimmer() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: List.generate(4, (index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            height: 120,
          ),
        );
      }),
    );
  }

  Widget _buildHealthOverview(DashboardProvider provider) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.outline, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fleet Health Overview',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
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
              child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: 0,
                    maximum: 100,
                    showLabels: false,
                    showTicks: false,
                    axisLineStyle: const AxisLineStyle(
                      thickness: 0.1,
                      cornerStyle: CornerStyle.bothCurve,
                      color: AppColors.outline,
                      thicknessUnit: GaugeSizeUnit.factor,
                    ),
                    pointers: <GaugePointer>[
                      RangePointer(
                        value: provider.averageHealth.toDouble(),
                        width: 0.1,
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
                              style: AppTextStyles.headlineMedium.copyWith(
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
            const SizedBox(height: 16),
            _buildHealthIndicators(),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildHealthIndicator('Excellent', 85, AppColors.success),
        _buildHealthIndicator('Good', 70, AppColors.primary),
        _buildHealthIndicator('Fair', 50, AppColors.warning),
        _buildHealthIndicator('Poor', 30, AppColors.error),
      ],
    );
  }

  Widget _buildHealthIndicator(String label, int threshold, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCriticalAlerts(DashboardProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Critical Alerts',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${provider.criticalMaintenance.length} issues',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...provider.criticalMaintenance.take(3).map((maintenance) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MaintenanceAlertCard(maintenance: maintenance),
          );
        }),
        if (provider.criticalMaintenance.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Navigate to all maintenance
                },
                child: Text(
                  'View all ${provider.criticalMaintenance.length} issues',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentEquipment(DashboardProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Equipment',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...provider.recentEquipment.take(3).map((equipment) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EquipmentCard(
              equipment: equipment,
              onTap: () => _navigateToEquipmentDetails(context, equipment),
              onEdit: () => _showEditEquipmentDialog(context, equipment),
              onDelete: () => _showDeleteEquipmentDialog(context, equipment.id),
              isSelected: false,
            ),
          );
        }),
        if (provider.recentEquipment.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Navigate to equipment list
                  _navigateToEquipmentScreen(context);
                },
                child: Text(
                  'View all ${provider.recentEquipment.length} equipment',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 70),
      child: FloatingActionButton(
        onPressed: () {
          // Quick action - report maintenance or add equipment
          _showQuickActionsDialog(context);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        child: const Icon(Icons.add, size: 24),
      ),
    );
  }

  // Navigation Methods
  void _navigateToEquipmentScreen(BuildContext context) {
    // This would navigate to the main equipment screen
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigating to Equipment Screen')),
    );
  }

  void _navigateToEquipmentDetails(BuildContext context, Equipment equipment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EquipmentDetailsScreen(equipment: equipment),
      ),
    );
  }

  void _showEditEquipmentDialog(BuildContext context, Equipment equipment) {
    // This would show the edit equipment dialog
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
              // Delete equipment logic would go here
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

  void _showQuickActionsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Actions',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            _buildQuickActionItem(
              context,
              Icons.add,
              'Add New Equipment',
              'Register new equipment to fleet',
              () {
                Navigator.pop(context);
                _showAddEquipmentDialog(context);
              },
            ),
            _buildQuickActionItem(
              context,
              Icons.build_outlined,
              'Report Maintenance',
              'Create maintenance request',
              () {
                Navigator.pop(context);
                _showReportMaintenanceDialog(context);
              },
            ),
            _buildQuickActionItem(
              context,
              Icons.assignment_outlined,
              'Create Project',
              'Start new construction project',
              () {
                Navigator.pop(context);
                _showCreateProjectDialog(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
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

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
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