import 'package:flutter/material.dart';

class AppConstants {
  // App Name
  static const String appName = "FixItPro";

  // Colors
  static const Color primaryColor = Color(0xFF2663EE);
  static const Color secondaryColor = Color(0xFF00C569);
  static const Color accentColor = Color(0xFFFF9800);
  static const Color textColor = Color(0xFF212121);
  static const Color lightTextColor = Color(0xFF757575);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);
  static const Color warningColor = Color(0xFFFFA726);
  static const Color dividerColor = Color(0xFFE0E0E0);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3D5CFF), Color(0xFF2E4BFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Text Styles
  static TextStyle get headingStyle => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
    fontFamily: 'Poppins',
  );

  static TextStyle get subheadingStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textColor,
    fontFamily: 'Poppins',
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textColor,
    fontFamily: 'Poppins',
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: whiteColor,
    fontFamily: 'Poppins',
  );

  // Padding
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Border Radius
  static const double defaultBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static const double cardBorderRadius = 16.0;

  // Animation Duration
  static const Duration defaultDuration = Duration(milliseconds: 300);

  // Service Types
  static const Map<String, String> serviceTypeLabels = {
    'repair': 'Repair',
    'installation': 'Installation',
    'installationWithMaterial': 'Installation with Material',
  };

  // Tier Types
  static const Map<String, String> tierTypeLabels = {
    'basic': 'Basic',
    'standard': 'Standard',
    'premium': 'Premium',
  };

  // Booking Status
  static const Map<String, String> bookingStatusLabels = {
    'pending': 'Pending',
    'confirmed': 'Confirmed',
    'inProgress': 'In Progress',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
    'rescheduled': 'Rescheduled',
  };

  // Booking Status Colors
  static const Map<String, Color> bookingStatusColors = {
    'pending': Color(0xFFFFA726),
    'confirmed': Color(0xFF2196F3),
    'inProgress': Color(0xFF9C27B0),
    'completed': Color(0xFF00C569),
    'cancelled': Color(0xFFFF3D00),
    'rescheduled': Color(0xFF607D8B),
  };

  // Input Decoration
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: whiteColor,
      labelStyle: TextStyle(color: lightTextColor),
      hintStyle: TextStyle(color: lightTextColor),
      contentPadding: EdgeInsets.symmetric(
        horizontal: defaultPadding,
        vertical: defaultPadding,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(buttonBorderRadius),
        borderSide: BorderSide(color: dividerColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(buttonBorderRadius),
        borderSide: BorderSide(color: dividerColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(buttonBorderRadius),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(buttonBorderRadius),
        borderSide: BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(buttonBorderRadius),
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
    );
  }

  // Button Style
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: whiteColor,
    textStyle: buttonTextStyle,
    padding: EdgeInsets.symmetric(
      horizontal: defaultPadding,
      vertical: defaultPadding,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonBorderRadius),
    ),
    elevation: 2,
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: whiteColor,
    foregroundColor: primaryColor,
    textStyle: buttonTextStyle.copyWith(color: primaryColor),
    padding: EdgeInsets.symmetric(
      horizontal: defaultPadding,
      vertical: defaultPadding,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonBorderRadius),
      side: BorderSide(color: primaryColor, width: 2),
    ),
    elevation: 0,
  );

  // Time Slots
  static const List<String> timeSlots = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
    '06:00 PM',
    '07:00 PM',
  ];

  // Responsive utilities
  static double getResponsiveFontSize(
    BuildContext context,
    double baseFontSize,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Scale font based on screen width
    if (screenWidth < 360) {
      return baseFontSize * 0.8; // Smaller phones
    } else if (screenWidth < 480) {
      return baseFontSize * 0.9; // Regular phones
    } else if (screenWidth < 600) {
      return baseFontSize; // Large phones
    } else {
      return baseFontSize * 1.1; // Tablets and larger
    }
  }

  static EdgeInsets getResponsivePadding(
    BuildContext context, {
    bool small = false,
    EdgeInsets? custom,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    double basePadding = small ? smallPadding : defaultPadding;

    if (custom != null) {
      double factor = 1.0;
      if (screenWidth < 360) {
        factor = 0.75;
      } else if (screenWidth < 480) {
        factor = 0.9;
      }

      return EdgeInsets.only(
        left: custom.left * factor,
        top: custom.top * factor,
        right: custom.right * factor,
        bottom: custom.bottom * factor,
      );
    }

    if (screenWidth < 360) {
      return EdgeInsets.all(basePadding * 0.75); // Smaller phones
    } else if (screenWidth < 480) {
      return EdgeInsets.all(basePadding * 0.9); // Regular phones
    } else {
      return EdgeInsets.all(basePadding); // Large phones and tablets
    }
  }

  static double getResponsiveWidth(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * (percentage / 100);
  }

  static double getResponsiveHeight(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * (percentage / 100);
  }

  // Helper to get responsive dimensions
  static double getResponsiveDimension(
    BuildContext context,
    double baseDimension,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 360) {
      return baseDimension * 0.8; // Smaller phones
    } else if (screenWidth < 480) {
      return baseDimension * 0.9; // Regular phones
    } else if (screenWidth < 600) {
      return baseDimension; // Large phones
    } else {
      return baseDimension * 1.2; // Tablets and larger
    }
  }

  // Helper to determine if screen is small
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  // Helper to determine if screen is medium
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 360 && width < 480;
  }

  // Helper to determine if screen is large
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 480;
  }

  // Responsive text styles that adapt to screen size
  static TextStyle getResponsiveHeadingStyle(BuildContext context) {
    return TextStyle(
      fontSize: getResponsiveFontSize(context, 24),
      fontWeight: FontWeight.bold,
      color: textColor,
      fontFamily: 'Poppins',
    );
  }

  static TextStyle getResponsiveSubheadingStyle(BuildContext context) {
    return TextStyle(
      fontSize: getResponsiveFontSize(context, 18),
      fontWeight: FontWeight.w600,
      color: textColor,
      fontFamily: 'Poppins',
    );
  }

  static TextStyle getResponsiveBodyTextStyle(BuildContext context) {
    return TextStyle(
      fontSize: getResponsiveFontSize(context, 16),
      color: textColor,
      fontFamily: 'Poppins',
    );
  }

  static TextStyle getResponsiveSmallTextStyle(BuildContext context) {
    return TextStyle(
      fontSize: getResponsiveFontSize(context, 14),
      color: lightTextColor,
      fontFamily: 'Poppins',
    );
  }

  static TextStyle getResponsiveCaptionStyle(BuildContext context) {
    return TextStyle(
      fontSize: getResponsiveFontSize(context, 12),
      color: lightTextColor,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w500,
    );
  }
}
