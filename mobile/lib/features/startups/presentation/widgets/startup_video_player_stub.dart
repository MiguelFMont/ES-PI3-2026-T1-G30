// Autor: Gabriel Martins de Almeida
// RA: 25006162

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

Widget buildStartupVideoPlayer(
  String assetPath,
  BorderRadius borderRadius, {
  required bool controls,
  required bool preview,
  required bool autoplay,
  required String objectFit,
}) {
  return ClipRRect(
    borderRadius: borderRadius,
    child: Container(
      color: const Color(0xFFF7F8FB),
      alignment: Alignment.center,
      child: const Icon(
        Icons.play_arrow_rounded,
        color: AppColors.primary,
        size: 34,
      ),
    ),
  );
}
