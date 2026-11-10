import 'package:flutter/material.dart';

class AppColors {
  // Figma Core Brand Palette
  static const Color primaryViolet = Color(0xFF5619F6); // Electric Royal Violet
  static const Color primaryVioletDark = Color(0xFF4510D1);
  static const Color primaryVioletLight = Color(0xFF6F3CF8);
  static const Color surfaceVioletTint = Color(0xFFF3F0FF);

  // Figma CTA & Accent Colors
  static const Color accentYellow = Color(0xFFF7CA43); // Warm Golden Yellow
  static const Color accentYellowHover = Color(0xFFE5B832);
  static const Color yellowButtonText = Color(0xFF18181B); // Dark Charcoal

  // Floating Action Button & Status Accents
  static const Color fabGreen = Color(0xFF15CA91); // Emerald Mint Green
  static const Color sparklePurple = Color(0xFF8B5CF6);
  static const Color deleteRed = Color(0xFFEF4444);

  // Surface & Canvas
  static const Color canvasViolet = Color(0xFF5619F6);
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFEDE9FE);
  
  // Folder / Category Badge in Cards
  static const Color folderBackground = Color(0xFFF1EEFF);
  static const Color folderIcon = Color(0xFF5619F6);
  
  // Text Colors
  static const Color textOnPurple = Colors.white;
  static const Color textOnPurpleMuted = Color(0xFFD4C8FF);
  static const Color cardTitle = Color(0xFF18181B);
  static const Color cardSubtitle = Color(0xFF64748B);
  static const Color iconMuted = Color(0xFF94A3B8);

  // Form Inputs on Purple Screen
  static const Color inputPurpleFill = Color(0x1AFFFFFF);
  static const Color inputPurpleBorder = Color(0x66FFFFFF);
  static const Color inputPurpleBorderFocused = Colors.white;

  // Bottom Navigation Dock
  static const Color navBackground = Colors.white;
  static const Color navSelected = Color(0xFF5619F6);
  static const Color navUnselected = Color(0xFF94A3B8);

  // Shadows
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x18000000),
    blurRadius: 16,
    offset: Offset(0, 6),
    spreadRadius: 0,
  );

  static const BoxShadow linkCardShadow = BoxShadow(
    color: Color(0x12000000),
    blurRadius: 12,
    offset: Offset(0, 4),
    spreadRadius: 0,
  );

  static const BoxShadow fabShadow = BoxShadow(
    color: Color(0x6615CA91),
    blurRadius: 16,
    offset: Offset(0, 6),
    spreadRadius: 0,
  );

  static const BoxShadow floatingNavShadow = BoxShadow(
    color: Color(0x28000000),
    blurRadius: 24,
    offset: Offset(0, 8),
    spreadRadius: 0,
  );

  // Legacy mappings for backwards-compatibility
  static const Color background = primaryViolet;
  static const Color primaryNavy = primaryViolet;
  static const Color brandDark = primaryVioletDark;
  static const Color logoBackground = surfaceVioletTint;
  static const Color subtitle = textOnPurpleMuted;
  static const Color searchButtonBackground = Color(0x26FFFFFF);
  static const Color linkBadgeBackground = Color(0xFFF1EEFF);
  static const Color linkBadgeIcon = primaryViolet;
  static const Color tagBackground = Color(0xFFF1EEFF);
  static const Color tagText = primaryViolet;
  static const Color navBorder = Colors.transparent;
  static const Color navInactive = navUnselected;
  static const Color navActiveRed = primaryViolet;
}
