import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';
import 'package:horeca_app/features/home/presentation/home_screen.dart';
import 'package:horeca_app/features/request/presentation/request_screen.dart';
import 'package:horeca_app/features/inventory/presentation/inventory_screen.dart';
import 'package:horeca_app/features/history/presentation/history_screen.dart';
import 'package:horeca_app/features/settings/presentation/settings_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/request', builder: (_, __) => const RequestScreen()),
        GoRoute(path: '/inventory', builder: (_, __) => const InventoryScreen()),
        GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ),
  ],
);

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({required this.child, super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateIndex(context),
        onTap: (index) => _onTap(context, index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: l10n.appTitle),
          BottomNavigationBarItem(icon: const Icon(Icons.history), label: l10n.history),
          BottomNavigationBarItem(icon: const Icon(Icons.settings), label: l10n.settings),
        ],
      ),
    );
  }
  int _calculateIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }
  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/'); break;
      case 1: context.go('/history'); break;
      case 2: context.go('/settings'); break;
    }
  }
}
