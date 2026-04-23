// lib/shared/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // impede instanciação

  // ── Cores Principais ──────────────────────────────────────────
  static const Color primary        = Color(0xFFE91E63);
  static const Color foreground     = Color(0xFF37474F);
  static const Color background     = Color(0xFFFAFAFA);
  static const Color card           = Color(0xFFFFFFFF);

  // ── Cores Secundárias ─────────────────────────────────────────
  static const Color secondary         = Color(0xFFF5F5F5);
  static const Color muted             = Color(0xFFECEFF1);
  static const Color mutedForeground   = Color(0xFF78909C);
  static const Color accent            = Color(0xFF01579B);

  // ── Status ────────────────────────────────────────────────────
  static const Color success     = Color(0xFF4CAF50);
  static const Color destructive = Color(0xFFF44336);

  // ── Gráficos ──────────────────────────────────────────────────
  static const Color chart1 = Color(0xFFE91E63);
  static const Color chart2 = Color(0xFF01579B);
  static const Color chart3 = Color(0xFFFF9800);
  static const Color chart4 = Color(0xFF9C27B0);
  static const Color chart5 = Color(0xFF00BCD4);

  //── Estágios das Startups ──────────────────────────────────────

  static const Color stageExpansion = chart4; //roxo
  static const Colot stageOperation = chart2 // azul
  static const Color stageNew  = success // verde

}