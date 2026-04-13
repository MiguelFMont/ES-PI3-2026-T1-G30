import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/presentation/pages/cadastro_page.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/welcome': (context) => const WelcomePage(),
    '/register': (context) => const CadastroPage(),
    '/login': (context) => const LoginPage(),
    '/home': (context) => const Scaffold(body: Center(child: Text('Home'))),
  };
}
