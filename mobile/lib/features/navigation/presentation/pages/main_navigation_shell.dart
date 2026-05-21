import 'package:flutter/material.dart';
import 'package:mesclainvest/core/theme/app_colors.dart';
import 'package:mesclainvest/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:mesclainvest/features/perfil/presentation/pages/perfil_page.dart';
import 'package:mesclainvest/features/startups/presentation/pages/startups_page.dart';
import 'package:mesclainvest/features/trading/presentation/pages/balcao_page.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    DashboardPage(),
    StartupsPage(),
    BalcaoPage(),
    PerfilPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.mutedForeground,
              backgroundColor: Colors.white,
              elevation: 0,
              iconSize: 24,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              showUnselectedLabels: true,
              onTap: (index) {
                if (_currentIndex == index) return;
                setState(() => _currentIndex = index);
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.rocket_launch_outlined),
                  activeIcon: Icon(Icons.rocket_launch),
                  label: 'Startups',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.swap_horiz),
                  activeIcon: Icon(Icons.swap_horiz),
                  label: 'Balcão',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
