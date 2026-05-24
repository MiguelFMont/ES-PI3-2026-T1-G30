// Autor: Miguel Fernandes Monteiro — RA: 25014808

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Badge de texto colorido, usado para categorias e status.
///
/// Ex.: "Investidor Mescla", "Não Verificado"
class PerfilBadge extends StatelessWidget {
  const PerfilBadge({
    super.key,
    required this.texto,
    required this.cor,
    required this.textoCor,
  });

  final String texto;
  final Color cor;
  final Color textoCor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textoCor,
        ),
      ),
    );
  }
}

/// Badge que indica se o usuário tem MFA (verificação em dois fatores) ativo.
///
/// Exibe "Verificado" (verde) ou "Não Verificado" (vermelho) conforme [mfaAtivo].
class BadgeVerificado extends StatelessWidget {
  const BadgeVerificado({super.key, required this.mfaAtivo});

  final bool mfaAtivo;

  @override
  Widget build(BuildContext context) {
    final cor = mfaAtivo ? Colors.green : AppColors.destructive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            mfaAtivo ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 12,
            color: cor,
          ),
          const SizedBox(width: 4),
          Text(
            mfaAtivo ? 'Verificado' : 'Não Verificado',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}
