// lib/features/auth/presentation/pages/splash_page.dart
// Autor: Miguel Fernandes Monteiro — RA: 25014808

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mesclainvest/app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/session_manager.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _verificarSessao();
  }

  Future<void> _verificarSessao() async {
    // Mantem a splash visivel por um curto periodo antes de decidir a rota.
    await Future.delayed(const Duration(milliseconds: 1800));
    String? token;

    try {
      // No navegador, o storage pode falhar ou retornar estado inconsistente.
      // Em vez de quebrar a rota inicial, tentamos ler a sessao com tolerancia.
      token = await SessionManager.getToken();
    } catch (_) {
      // Se o storage falhar, limpamos qualquer resto de sessao e seguimos como
      // usuario deslogado para evitar loop ou tela branca na inicializacao.
      await SessionManager.fazerLogout();
    }

    if (!mounted) return;
    // Com sessao valida vai para a shell autenticada; sem sessao vai para /welcome.
    Navigator.of(
      context,
    ).pushReplacementNamed(token != null ? AppRoutes.main : AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: Stack(
        children: [
          _buildDecoracoes(),
          SafeArea(
            child: Center(
              // A splash continua sendo a primeira tela renderizada depois do
              // bootstrap, entao qualquer falha anterior nao pode mais matar a UI.
              child: Column(
                children: [
                  const Spacer(),
                  _buildLogo(),
                  const Spacer(),
                  _buildRodape(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Círculos decorativos ──────────────────────────────────────────────────
  Widget _buildDecoracoes() {
    return Stack(
      children: [
        Positioned(
          top: -60,
          right: -60,
          child: _circulo(
            220,
            AppColors.lavanda.withValues(alpha: 0.1),
            borderWidth: 40,
          ),
        ),
        Positioned(
          bottom: 120,
          left: -80,
          child: _circulo(
            260,
            AppColors.primary.withValues(alpha: 0.3),
            borderWidth: 50,
          ),
        ),
        Positioned(
          top: 220,
          right: -40,
          child: _circulo(120, AppColors.primary.withValues(alpha: 0.12)),
        ),
      ],
    );
  }

  Widget _circulo(double size, Color cor, {double? borderWidth}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: borderWidth == null ? cor : null,
        border: borderWidth != null
            ? Border.all(color: cor, width: borderWidth)
            : null,
      ),
    );
  }

  // ─── Logo ─────────────────────────────────────────────────────────
  Widget _buildLogo() {
    return Column(
      children: [
        // Ícoe
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.lavanda.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.lavanda.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Image.asset(
              'assets/images/logoBranca.png',
              width: 48,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Nome
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Mescla',
                style: GoogleFonts.nunito(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'Invest',
                style: GoogleFonts.nunito(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Slogan
        Text(
          'Invista no futuro das startups',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.lavanda.withValues(alpha: 0.5),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  // ─── Rodapé ────────────────────────────────────────────────────────────────
  Widget _buildRodape() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 48),
      child: Column(
        children: [
          SizedBox(
            width: 40,
            child: LinearProgressIndicator(
              backgroundColor: AppColors.lavanda.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'v1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.lavanda.withValues(alpha: 0.25),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
