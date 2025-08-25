import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF00698F);
  static const background = Color(0xFFF7F7F7);
  static const border = Color(0xFFCCCCCC);
  static const labelText = Color(0xFF666666);
  static const buttonText = Colors.white;
  static const textButton = Colors.black87;
  static const textLink = Colors.black54;
}

class AppTextStyles {
  static const title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const label = TextStyle(
    color: AppColors.labelText,
  );

  static const button = TextStyle(
    fontWeight: FontWeight.bold,
    color: AppColors.buttonText,
  );

  static const forgotPassword = TextStyle(
    fontSize: 12,
    color: AppColors.textButton,
  );

  static const registerLink = TextStyle(
    fontSize: 12,
    color: AppColors.textLink,
  );
}

class AppInputDecoration {
  static InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.label,
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: AppColors.primary),
      ),
    );
  }
}

class AppButtonStyles {
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    ),
  );

  static ButtonStyle textButtonNoPadding = TextButton.styleFrom(
    padding: EdgeInsets.zero,
    minimumSize: const Size(50, 30),
  );
}
