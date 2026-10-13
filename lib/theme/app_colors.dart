import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFF8FAFC);
  static const Color primaryNavy = Color(0xFF142A57);
  static const Color brandDark = Color(0xFF1D3557);
  static const Color logoBackground = Color(0xFFDCE8FD);
  static const Color subtitle = Color(0xFF7A889B);
  static const Color searchButtonBackground = Color(0xFFEBF1FD);
  
  // Workspace Card
  static const Color cardBackground = Colors.white;
  static const Color folderBackground = Color(0xFFEBF1FD);
  static const Color folderIcon = Color(0xFF2B4C8C);
  static const Color iconMuted = Color(0xFF94A3B8);
  static const Color cardTitle = Color(0xFF111827);
  static const Color cardSubtitle = Color(0xFF94A3B8);
  
  // Link Card
  static const Color sparklePurple = Color(0xFF8B5CF6);
  static const Color deleteRed = Color(0xFFEF4444);
  static const Color linkBadgeBackground = Color(0xFFEEF4FF);
  static const Color linkBadgeIcon = Color(0xFF2563EB);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color tagBackground = Color(0xFFEFF6FF);
  static const Color tagText = Color(0xFF2563EB);

  // Floating Action Button
  static const Color fabGreen = Color(0xFF00D285);
  
  // Bottom Navigation
  static const Color navBackground = Colors.white;
  static const Color navBorder = Color(0xFFF1F5F9);
  static const Color navInactive = Color(0xFF475569);
  static const Color navActiveRed = Color(0xFFE03A3A);

  // Shadows
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x0C142A57),
    blurRadius: 18,
    offset: Offset(0, 8),
    spreadRadius: 0,
  );

  static const BoxShadow linkCardShadow = BoxShadow(
    color: Color(0x08000000),
    blurRadius: 10,
    offset: Offset(0, 4),
    spreadRadius: 0,
  );

  static const BoxShadow fabShadow = BoxShadow(
    color: Color(0x5500D285),
    blurRadius: 16,
    offset: Offset(0, 6),
  );
}
