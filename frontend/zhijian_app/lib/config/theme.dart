import 'package:flutter/material.dart';

/// 智健 App Theme — dark, premium fitness vibe.
class ZhiJianTheme {
  static const Color primary = Color(0xFFFF6D00); // Heat orange
  static const Color secondary = Color(0xFF00E5FF); // Cyan accent
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF262626);
  static const Color text = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFCA28);
  static const Color error = Color(0xFFE53935);

  // Personality colors
  static const Map<String, Color> personalityColors = {
    'strict_pro': Color(0xFFE53935),
    'gym_bro': Color(0xFFFF6D00),
    'cute_cheerleader': Color(0xFF64B5F6),
    'playful_tsundere': Color(0xFFE040FB),
    'innocent_rookie': Color(0xFF66BB6A),
  };

  static const Map<String, String> personalityEmojis = {
    'strict_pro': '🗿',
    'gym_bro': '🔥',
    'cute_cheerleader': '✨',
    'playful_tsundere': '😤',
    'innocent_rookie': '🌱',
  };

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: primary,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          surface: surface,
          error: error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: primary,
          unselectedItemColor: textSecondary,
          type: BottomNavigationBarType.fixed,
        ),
        cardTheme: CardThemeData(
          color: surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
        fontFamily: 'PingFang SC',
      );
}
