import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.primaryDark,
        surface: AppColors.white,
      ),
      
      // Personalización del AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Personalización del TabBar
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.white,
        unselectedLabelColor: Color(0xB3FFFFFF),
        indicatorColor: AppColors.white,
      ),
      
      scaffoldBackgroundColor: AppColors.white,
    );
  }
}