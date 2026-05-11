
// Autor: Miguel Fernandes Monteiro - RA: 25014808

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class MesclaOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double width;
  final IconData? icon;

  const MesclaOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width = 200,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.destructive.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.destructive.withOpacity(0.07),
          foregroundColor: AppColors.destructive,
          elevation: 0,
          side: BorderSide(
            color: AppColors.destructive.withOpacity(0.30),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: SizedBox(
          height: 60,
          width: width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: AppColors.destructive),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.destructive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}