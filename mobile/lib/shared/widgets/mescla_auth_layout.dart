// lib/shared/widgets/mescla_auth_layout.dart
// Autor: Miguel Fernandes Monteiro - RA: 25014808

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'mescla_logo.dart';

class MesclaAuthLayout extends StatelessWidget {
  final List<Widget> children;

  const MesclaAuthLayout({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final tecladoAberto = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: AppColors.card,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: SizedBox(
            height:
                MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
            child: Column(
              children: [
                MesclaHeader(tecladoAberto: tecladoAberto),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MesclaHeader extends StatelessWidget {
  final bool tecladoAberto;

  const MesclaHeader({super.key, required this.tecladoAberto});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: tecladoAberto ? 40 : 80,
        ),
        const MesclaLogo(),
        const SizedBox(height: 32),
      ],
    );
  }
}