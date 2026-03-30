import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/cadastro_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/login': (context) => const LoginPage(),
    '/register': (context) => const CadastroPage(),
    '/home': (context) => const Scaffold(body: Center(child: Text('Home')))
  };
}