import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/settings/presentation/tabs/departments_tab.dart';
import 'package:horeca_app/features/settings/presentation/tabs/categories_tab.dart';
import 'package:horeca_app/features/settings/presentation/tabs/products_tab.dart';
import 'package:horeca_app/features/settings/presentation/tabs/theme_tab.dart';
import 'package:horeca_app/features/settings/presentation/tabs/establishment_tab.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 5, // убрали "Язык"
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1C2B) : const Color(0xFFF5F5DC),
        appBar: AppBar(
          title: const Text('Настройки'),
          bottom: const TabBar(
            labelColor: Colors.orange,
            isScrollable: true,
            tabs: [
              Tab(text: 'Заведение'),
              Tab(text: 'Отделы'),
              Tab(text: 'Категории'),
              Tab(text: 'Товары'),
              Tab(text: 'Тема'),
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