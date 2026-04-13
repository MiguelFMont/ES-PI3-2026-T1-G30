// lib/shared/widgets/mescla_logo.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class MesclaLogo extends StatelessWidget {
  final double fontSize;
  final double imageWidth;
  final List<Color> gradientColors;

  const MesclaLogo({
    super.key,
    this.fontSize = 30,
    this.imageWidth = 45,
    this.gradientColors = const [AppColors.foreground, AppColors.primary],
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: Text(
            'MesclaInvest',
            style: GoogleFonts.nunito(
              textStyle: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Image.asset(
          'assets/images/logoBranca.png',
          width: imageWidth,
          color: AppColors.primary,
        ),
      ],
    );
  }
}