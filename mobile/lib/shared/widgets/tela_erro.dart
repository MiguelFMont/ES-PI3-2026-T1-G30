// Autor: Miguel Fernandes Monteiro — RA: 25014808

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Tela de erro centralizada com ícone, mensagem e botão de retry.
///
/// [mensagem] é o texto descritivo do erro.
/// [onTentarNovamente] é chamado ao pressionar "Tentar novamente".
class TelaErro extends StatelessWidget {
  const TelaErro({
    super.key,
    required this.mensagem,
    required this.onTentarNovamente,
  });

  final String mensagem;
  final VoidCallback onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off,
              color: AppColors.mutedForeground,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              onPressed: onTentarNovamente,
            ),
          ],
        ),
      ),
    );
  }
}
