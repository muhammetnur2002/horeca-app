import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/settings/presentation/tabs/departments_tab.dart';
import 'package:horeca_app/features/settings/presentation/tabs/categories_tab.dart';
import 'package:horeca_app/features/settings/presentation/tabs/products_tab.dart';
import 'package:horeca_app/features/settings/presentation/tabs/theme_tab.dart';
import 'package:horeca_app/features/settings/presentation/tabs/establishment_tab.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1C2B) : const Color(0xFFF5F5DC),
        appBar: AppBar(
          title: Text(l10n.settings),
          bottom: TabBar(
            labelColor: Colors.orange,
            isScrollable: true,
            tabs: [
              Tab(text: l10n.establishmentTab),
              Tab(text: l10n.departmentsTab),
              Tab(text: l10n.categoriesTab),
              Tab(text: l10n.productsTab),
              Tab(text: l10n.themeTab),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            EstablishmentTab(),
            DepartmentsTab(),
            CategoriesTab(),
            ProductsTab(),
            ThemeTab(),
          ],
        ),
      ),
    );
  }
}