import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/core/theme/app_theme.dart';

class _NavItem {
  const _NavItem(this.label, this.icon, this.iconFilled);

  final String label;
  final IconData icon;
  final IconData iconFilled;
}

const _kNavItems = [
  _NavItem('Accueil', Icons.home_outlined, Icons.home_rounded),
  _NavItem('Donneurs', Icons.people_outline, Icons.people_rounded),
  _NavItem('Stock', Icons.bloodtype_outlined, Icons.bloodtype_rounded),
  _NavItem('Demandes', Icons.campaign_outlined, Icons.campaign_rounded),
  _NavItem('Profil', Icons.person_outline, Icons.person_rounded),
];

/// Coquille de navigation globale — §3.4 : `BottomNavigationBar` sous
/// 600px, `NavigationRail` étendu au-delà, contenu centré à 1200px max sur
/// les grands écrans.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < kMobileBreakpoint;

    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
        child: navigationShell,
      ),
    );

    if (isMobile) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (i) =>
              navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primaryLight,
          destinations: [
            for (final item in _kNavItems)
              NavigationDestination(
                icon: Icon(item.icon, color: AppColors.textSecondary),
                selectedIcon: Icon(item.iconFilled, color: AppColors.primary),
                label: item.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            minExtendedWidth: 240,
            backgroundColor: AppColors.surface,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (i) =>
                navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: _RailLogo(),
            ),
            selectedIconTheme: const IconThemeData(color: AppColors.primary),
            selectedLabelTextStyle: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
            unselectedIconTheme: const IconThemeData(
              color: AppColors.textSecondary,
            ),
            unselectedLabelTextStyle: const TextStyle(
              color: AppColors.textSecondary,
            ),
            destinations: [
              for (final item in _kNavItems)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.iconFilled),
                  label: Text(item.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1, color: AppColors.border),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _RailLogo extends StatelessWidget {
  const _RailLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.water_drop_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'DonVie',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}
