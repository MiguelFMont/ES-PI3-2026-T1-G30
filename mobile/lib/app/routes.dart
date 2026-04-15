import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/presentation/pages/cadastro_page.dart';
import '../../features/auth/presentation/pages/recover_password_page.dart';

class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const welcome = '/welcome';
  static const forgotPassword = '/forgot-password';

  static Map<String, Widget Function(BuildContext)> get routes => {

    welcome: (_) => WelcomePage(),
    register: (_) => CadastroPage(),
    login: (_) => LoginPage(),
    home: (_) => Scaffold(body: Center(child: Text('Home'))),
    forgotPassword: (_) => RecoverPasswordPage(),
  };
}
  