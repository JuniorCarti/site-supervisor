import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/theme/app_theme.dart';
import 'core/services/api_service.dart';
import 'core/services/equipment_service.dart';
import 'core/services/maintenance_service.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/providers/dashboard_provider.dart';
import 'features/auth/presentation/providers/equipment_provider.dart';
import 'features/auth/presentation/screens/dashboard_screen.dart';
import 'features/auth/presentation/screens/equipment_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/maintenance/presentation/providers/maintenance_provider.dart';
import 'features/maintenance/presentation/screens/report_maintenance_screen.dart';
import 'features/projects/presentation/screens/projects_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API service
  final apiService = ApiService();
  await apiService.init();
  
  runApp(MyApp(apiService: apiService));
}

class MyApp extends StatelessWidget {
  final ApiService apiService;

  const MyApp({
    super.key,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide the ApiService instance
        Provider.value(value: apiService),
        
        // Equipment Services
        ProxyProvider<ApiService, EquipmentService>(
          update: (context, apiService, previous) => EquipmentService(apiService),
        ),
        ChangeNotifierProxyProvider<EquipmentService, EquipmentProvider>(
          create: (context) => EquipmentProvider(context.read<EquipmentService>()),
          update: (context, equipmentService, previous) => previous!..updateEquipmentService(equipmentService),
        ),
        
        // Maintenance Services
        ProxyProvider<ApiService, MaintenanceService>(
          update: (context, apiService, previous) => MaintenanceService(apiService),
        ),
        ChangeNotifierProxyProvider<MaintenanceService, MaintenanceProvider>(
          create: (context) => MaintenanceProvider(context.read<MaintenanceService>()),
          update: (context, maintenanceService, previous) => previous!..updateMaintenanceService(maintenanceService),
        ),
        
        // Auth Provider
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(apiService),
        ),
        
        // Dashboard Provider
        ChangeNotifierProvider<DashboardProvider>(
          create: (context) => DashboardProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'SiteSupervisor',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AppWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/equipment': (context) => const EquipmentScreen(),
          '/maintenance': (context) => const ReportMaintenanceScreen(),
          '/report-maintenance': (context) => const ReportMaintenanceScreen(),
          '/projects': (context) => const ProjectsScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}

// Extension for EquipmentProvider
extension EquipmentProviderExtension on EquipmentProvider {
  void updateEquipmentService(EquipmentService equipmentService) {
    // Update equipment service reference if needed
  }
}

// Extension for MaintenanceProvider
extension MaintenanceProviderExtension on MaintenanceProvider {
  void updateMaintenanceService(MaintenanceService maintenanceService) {
    // Update maintenance service reference if needed
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Use WidgetsBinding to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading) {
      return const SplashScreen();
    }

    return authProvider.isAuthenticated
        ? const MainNavigationWrapper()
        : const LoginScreen();
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const EquipmentScreen(),
    const ReportMaintenanceScreen(),
    const ProjectsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_outlined, 'Dashboard'),
                _buildNavItem(1, Icons.construction_outlined, 'Equipment'),
                _buildNavItem(2, Icons.build_outlined, 'Maintenance'),
                _buildNavItem(3, Icons.assignment_outlined, 'Projects'),
                _buildNavItem(4, Icons.person_outlined, 'Profile'),
              ],
            ),
          ),
        ),
      ),
      // Floating Action Button for Quick Actions (only on Maintenance screen)
      floatingActionButton: _currentIndex == 2 ? _buildFloatingActionButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: isActive
                ? BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            child: Icon(
              icon,
              size: 24,
              color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 70),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReportMaintenanceScreen(),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        child: const Icon(Icons.add, size: 24),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.construction,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'SiteSupervisor',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intelligent Fleet Management',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}