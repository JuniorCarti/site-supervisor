import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

class AppConfig {
  static const String appName = 'SiteSupervisor';
  static const String appVersion = '1.0.0';
  static const String apiBaseUrl = 'http://localhost:8000';
  
  static ThemeData get lightTheme => AppTheme.lightTheme;
  
  static const List<Color> brandGradient = [
    Color(0xFF0066FF),
    Color(0xFF0052D4),
  ];
}