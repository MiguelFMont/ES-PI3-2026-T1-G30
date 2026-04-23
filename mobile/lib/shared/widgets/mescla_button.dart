// lib/shared/widgets/mescla_button.dart
// Autor: Miguel Fernandes Monteiro - RA: 25014808

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class MesclaButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double width;

  const MesclaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: SizedBox(
          height: 60,
          width: width,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.card,
              ),
            ),
          ),
        ),
      ),
    );
  }
}