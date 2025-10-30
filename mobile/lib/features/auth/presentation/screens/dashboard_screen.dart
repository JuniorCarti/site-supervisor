import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:badges/badges.dart' as badges;
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
      
      // Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavigationBar(),
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
            child: provider.currentUser?.avatar != null
                ? Image.network(provider.currentUser!.avatar!, fit: BoxFit.cover)
                : const Icon(Icons.person_outline, size: 20),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildWelcomeSection(DashboardProvider provider) {
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
          provider.currentUser?.name ?? 'Site Manager',
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
            child: EquipmentCard(equipment: equipment),
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
          // Quick action - report maintenance
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        child: const Icon(Icons.add, size: 24),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.dashboard_outlined, 'Dashboard', true),
              _buildNavItem(Icons.construction_outlined, 'Equipment', false),
              _buildNavItem(Icons.build_outlined, 'Maintenance', false),
              _buildNavItem(Icons.assignment_outlined, 'Projects', false),
              _buildNavItem(Icons.person_outlined, 'Profile', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 24,
          color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
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