// Autor: Miguel Fernandes Monteiro — RA: 25014808

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Container com card agrupando uma lista de itens de menu,
/// separados por divisores — exceto após o último item.
class SecaoMenu extends StatelessWidget {
  const SecaoMenu({super.key, required this.itens});

  final List<Widget> itens;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: List.generate(itens.length, (i) {
          final isUltimo = i == itens.length - 1;
          return Column(
            children: [
              itens[i],
              if (!isUltimo)
                const Divider(height: 1, indent: 56, color: AppColors.muted),
            ],
          );
        }),
      ),
    );
  }
}

/// Item individual de menu com ícone, título, subtítulo e trailing.
///
/// [icon] é exibido em um container arredondado com fundo primário translúcido.
/// [trailing] padrão é um chevron; passe `null` para ocultar.
class ItemMenu extends StatelessWidget {
  const ItemMenu({
    super.key,
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    this.onTap,
    this.trailing = const Icon(
      Icons.chevron_right,
      color: AppColors.mutedForeground,
      size: 20,
    ),
  });

  final IconData icon;
  final String titulo;
  final String subtitulo;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        titulo,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
      ),
      subtitle: Text(
        subtitulo,
        style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
      ),
      trailing: trailing,
    );
  }
}