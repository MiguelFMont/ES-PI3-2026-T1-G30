// Autor: Miguel Fernandes Monteiro — RA: 25014808

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Rótulo de seção em caixa alta com espaçamento de letras.
/// Ex.: "CONTA", "CARTEIRA DIGITAL"
class RotuloSecao extends StatelessWidget {
  const RotuloSecao(this.titulo, {super.key});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Text(
      titulo,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.mutedForeground,
      ),
    );
  }
}