import 'package:flutter/material.dart';
import 'package:mesclainvest/core/theme/app_colors.dart';

class BalcaoPage extends StatelessWidget {
  const BalcaoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.foreground,
        title: const Text('Balcão de Negociação'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 56,
                  color: AppColors.primary,
                ),
                SizedBox(height: 16),
                Text(
                  'Balcão de Negociação',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.foreground,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Ambiente de compra e venda entre investidores. Esta área será evoluída nas próximas entregas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
