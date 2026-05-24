// Autor: Miguel Fernandes Monteiro — RA: 25014808

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Exibe um par label/valor em coluna, usado em sumários estatísticos.
///
/// Ex.: "Patrimônio" / "R$ 12.500"
class ItemEstatistica extends StatelessWidget {
  const ItemEstatistica({super.key, required this.label, required this.valor});

  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.foreground,
          ),
        ),
      ],
    );
  }
}
