import 'package:flutter/material.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/welcome_page.dart';
import '../features/auth/presentation/pages/cadastro_page.dart';
import '../features/auth/presentation/pages/recover_password_page.dart';
import '../features/auth/presentation/pages/reset_password_page.dart';
import '../features/auth/presentation/pages/token_verification_page.dart';
import '../features/perfil/presentation/pages/perfil_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/startups/presentation/pages/catalog_page.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const welcome = '/welcome';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const tokenVerification = '/token-verification';
  static const perfil = '/perfil';
  static const catalog = '/catalog';

  static Map<String, Widget Function(BuildContext)> get routes => {
    splash: (_) => SplashPage(),
    welcome: (_) => WelcomePage(),
    register: (_) => CadastroPage(),
    login: (_) => LoginPage(),
    home: (_) => PerfilPage(),
    forgotPassword: (_) => RecoverPasswordPage(),
    resetPassword: (_) => ResetPasswordPage(),
    tokenVerification: (_) => TokenVerificationPage(),
    perfil: (_) => PerfilPage(),
    catalog: (_) => CatalogPage(),
  };
}
