import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color lightBlue = Color(0xFFEFF6FF);
  static const Color slateBlue = Color(0xFF0EA5E9);
  static const Color darkBg = Color(0xFF1E293B);

  static const Color statusNormal = Color(0xFF22C55E);
  static const Color statusWaspada = Color(0xFF3B82F6);
  static const Color statusSiaga = Color(0xFF0EA5E9);
  static const Color statusBahaya = Color(0xFFEF4444);

  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color pageBg = Color(0xFFF8FAFC);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
        ),
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: pageBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: textDark,
          elevation: 0,
          shadowColor: Color(0x1A000000),
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: const CardThemeData(
          color: cardBg,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
      );
}
