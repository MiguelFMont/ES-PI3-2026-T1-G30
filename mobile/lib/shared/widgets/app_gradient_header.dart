// lib/shared/widgets/app_gradient_header.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Cabeçalho com gradiente diagonal padrão do app. DA TELA DE PERFIL, MAS PODE SER REUTILIZADO EM OUTRAS TELAS QUE QUEIRAM SEGUIR O MESMO PADRÃO VISUAL.
///
/// [titulo] é exibido no canto inferior esquerdo.
/// [alturaExtra] é somada à altura da status bar (padrão: 160).
class AppGradientHeader extends StatelessWidget {
  const AppGradientHeader({
    super.key,
    required this.titulo,
    this.leading,
    this.alturaExtra = 160,
  });

  final String titulo;
  final Widget? leading;
  final double alturaExtra;

  static const _sobreposicaoCard = 48.0;

  @override
  Widget build(BuildContext context) {
    final alturaStatusBar = MediaQuery.of(context).padding.top;

    return Container(
      height: alturaStatusBar + alturaExtra,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.55, 0.55],
          colors: [AppColors.primary, Color(0xFFE92C6B)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: alturaStatusBar + 8,
          left: 24,
          right: 24,
          bottom: _sobreposicaoCard + 8,
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: leading != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leading!,
                    if (titulo.isNotEmpty) const SizedBox(height: 8),
                    if (titulo.isNotEmpty) _textoTitulo(),
                  ],
                )
              : _textoTitulo(),
        ),
      ),
    );
  }

  Widget _textoTitulo() => Text(
    titulo,
    style: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w800,
      fontSize: 26,
      letterSpacing: 0.1,
    ),
  );
}
