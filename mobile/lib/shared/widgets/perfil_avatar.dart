// Autor: Miguel Fernandes Monteiro — RA: 25014808

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/formatters/index.dart';

/// Avatar circular com as iniciais do [nome] do usuário.
///
/// [tamanho] define o diâmetro (padrão: 56).
/// [mostrarBotaoFoto] exibe um ícone de câmera no canto inferior direito.
class PerfilAvatar extends StatelessWidget {
  const PerfilAvatar({
    super.key,
    required this.nome,
    this.tamanho = 56,
    this.mostrarBotaoFoto = false,
  });

  final String nome;
  final double tamanho;
  final bool mostrarBotaoFoto;

  @override
  Widget build(BuildContext context) {
    final circulo = Container(
      width: tamanho,
      height: tamanho,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
      ),
      child: Center(
        child: Text(
          iniciais(nome).toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: tamanho * 0.357, // escala proporcional ao tamanho
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    if (!mostrarBotaoFoto) return circulo;

    return Stack(
      children: [
        circulo,
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.card,
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              size: 13,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
