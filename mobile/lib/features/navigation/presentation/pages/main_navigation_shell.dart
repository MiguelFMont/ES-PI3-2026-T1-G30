import 'package:flutter/material.dart';
import 'package:mesclainvest/core/theme/app_colors.dart';
import 'package:mesclainvest/features/balcao/presentation/pages/balcao_page.dart';
import 'package:mesclainvest/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:mesclainvest/features/perfil/presentation/pages/perfil_page.dart';
import 'package:mesclainvest/features/portfolio/presentation/screens/portfolio_screen.dart';
import 'package:mesclainvest/features/startups/presentation/pages/startups_page.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;

  static const List<Widget> _pages = [
    DashboardPage(),
    PortfolioScreen(),
    StartupsPage(),
    BalcaoPage(),
    PerfilPage(),
  ];

  static final List<BottomNavigationBarItem> _items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.grid_view_outlined, color: Colors.grey[600]),
      activeIcon: const Icon(Icons.grid_view_rounded, color: AppColors.primary),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.pie_chart_outline_rounded),
      activeIcon: Icon(Icons.pie_chart_rounded),
      label: 'Portfólio',
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
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex =
        widget.initialIndex >= 0 && widget.initialIndex < _pages.length
        ? widget.initialIndex
        : 0;
  }

  void _onTap(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  bool _isMobileLayout(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 640;

  Widget _buildBottomNavigationBar(BuildContext context) {
    if (_isMobileLayout(context)) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.mutedForeground,
            backgroundColor: Colors.white,
            elevation: 0,
            iconSize: 22,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            showUnselectedLabels: true,
            onTap: _onTap,
            items: _items,
          ),
        ),
      );
    }

    return SafeArea(
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
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            showUnselectedLabels: true,
            onTap: _onTap,
            items: _items,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }
}
