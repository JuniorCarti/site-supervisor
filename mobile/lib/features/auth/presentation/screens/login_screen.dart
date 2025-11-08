import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:animations/animations.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/animated_button.dart';
import '../../../../shared/widgets/input_field.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // Added for registration
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  bool _isLogin = true;
  bool _obscurePassword = true;
  String _selectedRole = 'driver'; // Default role

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
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = context.read<AuthProvider>();
    
    if (_isLogin) {
      await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } else {
      await authProvider.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    return Scaffold(
      body: Stack(
        children: [
          // Background Image with Overlay
          _buildBackground(),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    
                    // Logo and Title
                    _buildHeader(),
                    
                    const SizedBox(height: 48),
                    
                    // Auth Card
                    OpenContainer(
                      closedColor: Colors.transparent,
                      openColor: AppColors.surface,
                      closedElevation: 0,
                      openElevation: 8,
                      closedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      transitionDuration: const Duration(milliseconds: 600),
                      closedBuilder: (context, action) {
                        return _buildAuthCard(authProvider);
                      },
                      openBuilder: (context, action) {
                        return _buildAuthCard(authProvider);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            'https://images.pexels.com/photos/60008/brown-coal-energy-garzweiler-bucket-wheel-excavators-60008.jpeg',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.black.withOpacity(0.4),
              Colors.black.withOpacity(0.6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo Container
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Lottie.asset(
              'assets/animations/construction.json',
              width: 50,
              height: 50,
              fit: BoxFit.contain,
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Title
        Text(
          'SiteSupervisor',
          style: AppTextStyles.headlineLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 10,
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(2, 2),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Intelligent Construction Fleet Management',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white.withOpacity(0.9),
            shadows: [
              Shadow(
                blurRadius: 5,
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuthCard(AuthProvider authProvider) {
    return Card(
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withOpacity(0.95),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  _isLogin ? 'Welcome Back' : 'Create Account',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  _isLogin 
                      ? 'Sign in to continue' 
                      : 'Join SiteSupervisor today',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Name Field (only for registration)
                if (!_isLogin)
                  Column(
                    children: [
                      InputField(
                        controller: _nameController,
                        label: 'Full Name',
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (!_isLogin && (value == null || value.isEmpty)) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                
                // Email Field
                InputField(
                  controller: _emailController,
                  label: 'Email Address',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Password Field
                InputField(
                  controller: _passwordController,
                  label: 'Password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword 
                          ? Icons.visibility_outlined 
                          : Icons.visibility_off_outlined,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                
                // Role Selection (only for registration)
                if (!_isLogin) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Select Role',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.outline),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'driver',
                        child: Text('Driver'),
                      ),
                      DropdownMenuItem(
                        value: 'manager',
                        child: Text('Manager'),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('Administrator'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedRole = value;
                        });
                      }
                    },
                    validator: (value) {
                      if (!_isLogin && (value == null || value.isEmpty)) {
                        return 'Please select a role';
                      }
                      return null;
                    },
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Error Message
                if (authProvider.error != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            authProvider.error!,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: authProvider.clearError,
                        ),
                      ],
                    ),
                  ),
                
                if (authProvider.error != null) const SizedBox(height: 16),
                
                // Submit Button
                AnimatedButton(
                  onPressed: _submit,
                  isLoading: authProvider.isLoading,
                  child: Text(
                    _isLogin ? 'Sign In' : 'Create Account',
                    style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Toggle Auth Mode
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin 
                          ? "Don't have an account?" 
                          : "Already have an account?",
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _toggleAuthMode,
                      child: Text(
                        _isLogin ? 'Sign Up' : 'Sign In',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
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
}