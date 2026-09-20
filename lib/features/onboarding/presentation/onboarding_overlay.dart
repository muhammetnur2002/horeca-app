import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';

class _OnboardingStep {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  const _OnboardingStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}

const _steps = [
  _OnboardingStep(
    icon: Icons.auto_awesome_rounded,
    color: AppColors.orange,
    title: 'Добро пожаловать в Akyl!',
    description:
        'Короткий тур — меньше минуты — поможет быстро освоиться. '
        'Его всегда можно пересмотреть в разделе «О программе».',
  ),
  _OnboardingStep(
    icon: Icons.assignment_outlined,
    color: AppColors.orange,
    title: 'Заявка на закупку',
    description:
        'Собирайте заявки по кухне, бару, складу и залу в пару касаний, '
        'затем делитесь готовым списком или сохраняйте PDF.',
  ),
  _OnboardingStep(
    icon: Icons.inventory_2_outlined,
    color: AppColors.green,
    title: 'Инвентаризация',
    description:
        'Фиксируйте фактические остатки по каждому товару — приложение '
        'само соберёт понятный отчёт.',
  ),
  _OnboardingStep(
    icon: Icons.nights_stay_outlined,
    color: AppColors.green,
    title: 'Закрытие смены',
    description:
        'Выручка, списания и десерты — всё в одном отчёте с PDF в конце '
        'каждой смены.',
  ),
  _OnboardingStep(
    icon: Icons.settings_outlined,
    color: Color(0xFF9966FF),
    title: 'Сотрудники и настройки',
    description:
        'Во вкладке «Настройки» добавляйте сотрудников, отделы, категории '
        'и товары, а также управляйте заведениями и темой оформления.',
  ),
];

/// Полноэкранный оверлей-тур из нескольких шагов. Показывается поверх
/// главного экрана один раз при первом входе (см. onboarding_repository.dart)
/// и может быть вызван повторно вручную из "О программе".
class OnboardingOverlay extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingOverlay({
    super.key,
    required this.onFinish,
  });

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _steps.length - 1) {
      widget.onFinish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _steps.length - 1;

    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          // Затемняющая подложка нарочно не зависит от темы приложения:
          // поверх неё всегда белый текст, чтобы тур одинаково хорошо
          // читался и в светлом, и в тёмном режиме.
          color: Colors.black.withOpacity(0.55),
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                    child: TextButton(
                      onPressed: widget.onFinish,
                      child: const Text('Пропустить',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _steps.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => _StepCard(step: _steps[i]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_steps.length, (i) {
                          final active = i == _page;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: active
                                  ? AppColors.orange
                                  : Colors.white.withOpacity(0.3),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text(isLast ? 'Начать работу' : 'Далее',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final _OnboardingStep step;
  const _StepCard({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: step.color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(step.icon, color: step.color, size: 42),
          ),
          const SizedBox(height: 28),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            step.description,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}
