// Autor: Miguel Fernandes Monteiro — RA: 25014808
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Campo de exibição de informação cadastral em card.
///
/// [editavel] controla se o chevron de edição é exibido (padrão: true).
/// [onTap] é chamado ao tocar no item (apenas quando [editavel] for true).
class CampoInfo extends StatelessWidget {
  const CampoInfo({
    super.key,
    required this.icon,
    required this.label,
    required this.valor,
    this.editavel = true,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String valor;
  final bool editavel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: editavel ? onTap : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.mutedForeground,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            valor,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.foreground,
            ),
          ),
        ),
        trailing: editavel
            ? const Icon(
                Icons.chevron_right,
                color: AppColors.mutedForeground,
                size: 20,
              )
            : null,
      ),
    );
  }
}