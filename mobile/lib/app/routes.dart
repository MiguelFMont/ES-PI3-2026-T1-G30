import 'package:flutter/material.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/welcome_page.dart';
import '../features/auth/presentation/pages/cadastro_page.dart';
import '../features/auth/presentation/pages/recover_password_page.dart';
import '../features/auth/presentation/pages/reset_password_page.dart';
import '../features/auth/presentation/pages/token_verification_page.dart';
import '../features/navigation/presentation/pages/main_navigation_shell.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/auth/presentation/pages/mfa_challenge_page.dart';
import '../features/startups/domain/startup_model.dart';
import '../features/startups/presentation/pages/catalog_page.dart';
import '../features/startups/presentation/pages/startup_details_page.dart';
import '../features/perfil/presentation/pages/informacoes_pessoais_page.dart';
import '../features/perfil/presentation/pages/mfa_page.dart';
import '../features/perfil/presentation/pages/senha_page.dart';
import '../features/portfolio/presentation/screens/extrato_page.dart';

class AppRoutes {
  static const splash = '/';
  static const main = '/main';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const welcome = '/welcome';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const tokenVerification = '/token-verification';
  static const perfil = '/perfil';
  static const catalog = '/catalog';
  static const startupDetail = '/startup-detail';
  static const informacoesPessoais = '/informacoes-pessoais';
  static const mfa = '/mfa';
  static const mfaChallenge = '/mfa-challenge';
  static const segurancaSenha = '/seguranca-senha';
  static const portfolio = '/portfolio';
  static const extrato = '/extrato';
  static const balcao = '/balcao';
  static const dashboard = '/dashboard';

  static int _resolveMainShellIndex(BuildContext context, int fallback) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    return arguments is int ? arguments : fallback;
  }

  static Map<String, Widget Function(BuildContext)> get routes => {
    splash: (_) => SplashPage(),
    main: (context) =>
        MainNavigationShell(initialIndex: _resolveMainShellIndex(context, 0)),
    welcome: (_) => WelcomePage(),
    register: (_) => CadastroPage(),
    login: (_) => LoginPage(),
    home: (context) =>
        MainNavigationShell(initialIndex: _resolveMainShellIndex(context, 0)),
    forgotPassword: (_) => RecoverPasswordPage(),
    resetPassword: (_) => ResetPasswordPage(),
    tokenVerification: (_) => TokenVerificationPage(),
    perfil: (context) =>
        MainNavigationShell(initialIndex: _resolveMainShellIndex(context, 4)),
    catalog: (_) => CatalogPage(),
    startupDetail: (context) {
      final startup = ModalRoute.of(context)?.settings.arguments;
      if (startup is Startup) {
        return StartupDetailsPage(startup: startup);
      }
      return const StartupDetailsArgumentErrorPage();
    },
    informacoesPessoais: (_) => InformacoesPage(),
    mfa: (_) => MfaPage(),
    mfaChallenge: (_) => MfaChallengePage(),
    segurancaSenha: (_) => SenhaPage(),
    portfolio: (context) =>
        MainNavigationShell(initialIndex: _resolveMainShellIndex(context, 1)),
    extrato: (_) => const ExtratoPage(),
    balcao: (context) =>
        MainNavigationShell(initialIndex: _resolveMainShellIndex(context, 3)),
    dashboard: (context) =>
        MainNavigationShell(initialIndex: _resolveMainShellIndex(context, 0)),
  };
}
