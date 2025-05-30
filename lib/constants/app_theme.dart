import 'package:flutter/material.dart';
import 'package:fixitpro/constants/app_constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppConstants.primaryColor,
      useMaterial3: true, // Enable Material 3 design
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryColor,
        primary: AppConstants.primaryColor,
        secondary: AppConstants.secondaryColor,
        background: AppConstants.backgroundColor,
        surface: AppConstants.whiteColor,
        error: AppConstants.errorColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppConstants.backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: AppConstants.whiteColor,
        foregroundColor: AppConstants.primaryColor,
        titleTextStyle: TextStyle(
          color: AppConstants.primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
      ),
      fontFamily: 'Poppins',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppConstants.textColor,
          fontFamily: 'Poppins',
        ),
        displayMedium: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppConstants.textColor,
          fontFamily: 'Poppins',
        ),
        displaySmall: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppConstants.textColor,
          fontFamily: 'Poppins',
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppConstants.textColor,
          fontFamily: 'Poppins',
        ),
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppConstants.textColor,
          fontFamily: 'Poppins',
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppConstants.textColor,
          fontFamily: 'Poppins',
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppConstants.textColor,
          fontFamily: 'Poppins',
        ),
        titleSmall: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppConstants.textColor,
          fontFamily: 'Poppins',
        ),
        bodyLarge: TextStyle(
          color: AppConstants.textColor,
          fontFamily: 'Poppins',
        ),
        bodyMedium: TextStyle(
          color: AppConstants.textColor,
          fontFamily: 'Poppins',
        ),
        bodySmall: TextStyle(
          color: AppConstants.lightTextColor,
          fontFamily: 'Poppins',
        ),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppConstants.textColor,
          fontFamily: 'Poppins',
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withAlpha(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.whiteColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: const BorderSide(
            color: AppConstants.primaryColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: const BorderSide(color: AppConstants.errorColor),
        ),
        hintStyle: const TextStyle(
          color: AppConstants.lightTextColor,
          fontFamily: 'Poppins',
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: AppConstants.textColor,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
        prefixIconColor: AppConstants.primaryColor,
        suffixIconColor: AppConstants.lightTextColor,
        floatingLabelStyle: const TextStyle(
          color: AppConstants.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: AppConstants.whiteColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.buttonBorderRadius,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          elevation: 0,
          shadowColor: AppConstants.primaryColor.withAlpha(60),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.primaryColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
          side: const BorderSide(color: AppConstants.primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.buttonBorderRadius,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppConstants.primaryColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return AppConstants.primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: AppConstants.lightTextColor),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.all(AppConstants.primaryColor),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return AppConstants.primaryColor;
          }
          return Colors.grey.shade400;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return AppConstants.primaryColor.withAlpha(128);
          }
          return Colors.grey.shade300;
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppConstants.dividerColor,
        thickness: 1,
        space: 32,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: Colors.grey.shade500,
        selectedIconTheme: const IconThemeData(size: 26),
        unselectedIconTheme: const IconThemeData(size: 24),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}
