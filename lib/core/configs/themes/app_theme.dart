// This file defines app theming and visual style configuration.

import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static final lightTheme = ThemeData(
      scaffoldBackgroundColor: AppColors.lightBackgroundColor,
      primaryColor: AppColors.primaryColor,
      brightness: Brightness.light,
      fontFamily: 'Satoshi',
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              elevation: 0,
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)))));

  static final darkTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.darkBackgroundColor,
    primaryColor: AppColors.primaryColor,
    brightness: Brightness.dark,
    fontFamily: 'Satoshi',
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            elevation: 0,
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30)))),
  );
}
