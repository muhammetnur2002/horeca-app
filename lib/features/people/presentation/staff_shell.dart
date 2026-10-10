/// Дверь сотрудника по макету: Главная (мои чаты), Смены, Профиль,
/// Уведомления. Склад и заявки заведения сюда не входят.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/landing/data/door_repository.dart';
import 'package:horeca_app/features/people/data/people_repository.dart';
import 'package:horeca_app/features/people/domain/people_calc.dart';
import 'package:horeca_app/features/people/domain/people_models.dart';
import 'package:horeca_app/features/people/presentation/people_profile_screen.dart';
import 'package:horeca_app/features/people/presentation/people_style.dart';
import 'package:horeca_app/features/people/presentation/people_work_sections.dart';

/// Сфера по специальности (docs/algorithms.md): кухня видит поваров,
/// бар — барменов и бариста.
String workSphereLabel(HospitalityRole role) {
  switch (role) {
    case HospitalityRole.cook:
      return 'кухня';
    case HospitalityRole.bartender:
    case HospitalityRole.barista:
      return 'бар';
    case HospitalityRole.waiter:
      return 'зал';
    case HospitalityRole.administrator:
    case HospitalityRole.manager:
      return 'управление';
  }
}

class StaffShell extends ConsumerStatefulWidget {
  const StaffShell({super.key});

  @override
  ConsumerState<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends ConsumerState<StaffShell> {
  // Профиль — главный экран сотрудника по макету.
  int _tab = 2;

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(peopleRepositoryProvider).me;
    // Пока профиля нет, вкладки не нужны: сначала создать профиль.
    if (me == null) return const PeopleProfileScreen();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: IndexedStack(index: _tab, children: [
        _StaffChatsPage(profile: me),
        _StaffShiftsPage(profile: me),
        const PeopleProfileScreen(),
        const _StaffNotificationsPage(),
      ]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border(
            top: BorderSide(
              color: (isDark ? AppColors.cream : AppColors.black).withOpacity(0.06),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.orange,
          unselectedItemColor: AppColors.muted,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Главная'),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_outlined),
                activeIcon: Icon(Icons.calendar_month_rounded),
                label: 'Смены'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Профиль'),
            BottomNavigationBarItem(
                icon: Icon(Icons.notifications_none_rounded),
                activeIcon: Icon(Icons.notifications_rounded),
                label: 'Уведомления'),
          ],
        ),
      ),
    );
  }
}

class _StaffPage extends ConsumerWidget {
  final String title;
  final List<Widget> children;
  const _StaffPage({required this.title, required this.children});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = PeopleColors(isDark);
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        foregroundColor: colors.text,
        title: Text(title, style: TextStyle(color: colors.text, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Сменить вход',
            onPressed: () => ref.read(doorProvider.notifier).reset(),
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
        ],
      ),
      body: Stack(children: [
        Positioned.fill(child: PeopleBackground(isDark: isDark)),
        ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 32), children: children),
      ]),
    );
  }
}

class _StaffChatsPage extends StatelessWidget {
  final PersonProfile profile;
  const _StaffChatsPage({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = PeopleColors(isDark);
    final specialties = collectSpecialties(profile.workplaces, now: DateTime.now());
    final spheres = {for (final s in specialties) workSphereLabel(s.role)}.toList();
    // Тексты пустых состояний — Grok 1, docs/совместная-работа.md (PR #15).
    final sphereText = spheres.isEmpty
        ? 'Специальность ещё не выбрана. Без неё вакансии вашей сферы не появятся.'
        : 'Ваша сфера: ${spheres.join(', ')}.';
    return _StaffPage(title: 'Главная', children: [
      Text(sphereText, style: TextStyle(color: colors.sub, height: 1.35)),
      const SizedBox(height: 14),
      PeopleSectionHeader(title: 'Вакансии вашей сферы', isDark: isDark),
      const SizedBox(height: 8),
      _EmptyCard(
        isDark: isDark,
        icon: Icons.work_outline_rounded,
        title: 'Вакансий вашей сферы пока нет',
        body: 'Когда заведение опубликует вакансию по вашей специальности, '
            'она появится здесь.',
      ),
      const SizedBox(height: 18),
      PeopleSectionHeader(title: 'Мои чаты', isDark: isDark),
      const SizedBox(height: 8),
      _EmptyCard(
        isDark: isDark,
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Откликов пока нет',
        body: 'Откройте вакансию и нажмите «Откликнуться». Пока владелец не '
            'одобрил разговор, можно отправить 3 сообщения.',
      ),
    ]);
  }
}

class _StaffShiftsPage extends StatelessWidget {
  final PersonProfile profile;
  const _StaffShiftsPage({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _StaffPage(title: 'Смены и стаж', children: [
      SpecialtiesSection(profile: profile, isDark: isDark),
      const SizedBox(height: 10),
      WorkplacesSection(profile: profile, isDark: isDark),
    ]);
  }
}

class _StaffNotificationsPage extends StatelessWidget {
  const _StaffNotificationsPage();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _StaffPage(title: 'Уведомления', children: [
      _EmptyCard(
        isDark: isDark,
        icon: Icons.notifications_none_rounded,
        title: 'Уведомлений нет',
        body: 'Здесь появятся одобрения и новые вакансии вашей сферы.',
      ),
    ]);
  }
}

class _EmptyCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String body;
  const _EmptyCard({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PeopleColors(isDark);
    return PeopleCard(
      isDark: isDark,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.orange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.orange),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.text)),
            const SizedBox(height: 4),
            Text(body, style: TextStyle(color: colors.sub, height: 1.4)),
          ]),
        ),
      ]),
    );
  }
}
