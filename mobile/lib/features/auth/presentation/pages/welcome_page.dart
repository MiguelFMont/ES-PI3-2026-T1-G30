// lib/features/auth/presentation/pages/welcome_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          Expanded(child: _ilustracao()),
          _card(context),
        ],
      ),
    );
  }

  Widget _ilustracao() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/logoBranca.png', height: 80),
        const SizedBox(height: 12),
        Text(
          'MesclaInvest',
          style: GoogleFonts.nunito(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Invista no futuro das startups',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titulo(),
          const SizedBox(height: 8),
          _subtitulo(),
          const SizedBox(height: 32),
          _botaoCadastrar(context),
          const SizedBox(height: 12),
          _linkLogin(context),
        ],
      ),
    );
  }

  Widget _titulo() {
    return const Text(
      'Comece a investir hoje',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.foreground,
      ),
    );
  }

  Widget _subtitulo() {
    return const Text(
      'Crie sua conta em menos de 2 minutos\ne acesse tokens de startups reais.',
      style: TextStyle(
        fontSize: 14,
        color: AppColors.mutedForeground,
        height: 1.5,
      ),
    );
  }

  Widget _botaoCadastrar(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/register'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Criar conta',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _linkLogin(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Já tem uma conta?',
          style: TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          style: TextButton.styleFrom(
            splashFactory: NoSplash.splashFactory,
            overlayColor: Colors.transparent,
          ),
          child: const Text(
            'Entrar',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}