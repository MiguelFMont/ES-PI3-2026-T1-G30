import 'package:flutter/material.dart';
import 'routes.dart';

class MesclaInvestApp extends StatelessWidget {
  const MesclaInvestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MesclaInvest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final builder = AppRoutes.routes[settings.name];
        if (builder == null) return null;

        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, _, _) => builder(context),
          transitionsBuilder: (_, animation, _, child) {
            var tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.ease));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      },
    );
  }
}