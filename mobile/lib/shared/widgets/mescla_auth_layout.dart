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
    final mq = MediaQuery.of(context);
    final fullHeight = mq.size.height - mq.padding.top - mq.padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.card,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: SizedBox(
            height: fullHeight,
            child: Column(
              children: [
                const MesclaHeader(),
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
  const MesclaHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 80),
        MesclaLogo(),
        SizedBox(height: 32),
      ],
    );
  }
}
