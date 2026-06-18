import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/settings/presentation/tabs/establishment_tab.dart';
import 'package:horeca_app/features/settings/presentation/tabs/departments_tab.dart';
import 'package:horeca_app/features/settings/presentation/tabs/categories_tab.dart';
import 'package:horeca_app/features/settings/presentation/tabs/products_tab.dart';
import 'package:horeca_app/features/settings/presentation/tabs/theme_tab.dart';
import 'package:horeca_app/features/settings/presentation/tabs/shift_tab.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            l10n.settings,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white
                          .withOpacity(isDark ? 0.06 : 0.5),
                      border: Border.all(
                        color: Colors.white
                            .withOpacity(isDark ? 0.1 : 0.6),
                      ),
                    ),
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.orange,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.muted,
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      dividerColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2),
                      tabs: [
                        Tab(text: l10n.establishmentTab),
                        Tab(text: l10n.departmentsTab),
                        Tab(text: l10n.categoriesTab),
                        Tab(text: l10n.productsTab),
                        const Tab(text: 'Смена'),
                        Tab(text: l10n.themeTab),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF0F1629),
                      Color(0xFF1A1040),
                      Color(0xFF0D1F35)
                    ]
                  : const [
                      Color(0xFFEEF2FF),
                      Color(0xFFF5F7FF),
                      Color(0xFFEEF2FF)
                    ],
            ),
          ),
          child: const TabBarView(
            children: [
              EstablishmentTab(),
              DepartmentsTab(),
              CategoriesTab(),
              ProductsTab(),
              ShiftTab(),
              ThemeTab(),
            ],
          ),
        ),
      ),
    );
  }
}