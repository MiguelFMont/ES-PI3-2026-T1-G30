import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/cadastro_page.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    // '/login': (context) => const LoginScreen(),
    '/login': (context) => const CadastroPage(),
    // '/home': (context) => const HomeScreen(),
  };
}