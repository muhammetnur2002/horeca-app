/// Специальности со стажем и места работы. Общие для профиля и вкладки
/// «Смены» двери сотрудника.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/people/data/people_repository.dart';
import 'package:horeca_app/features/people/domain/people_calc.dart';
import 'package:horeca_app/features/people/domain/people_models.dart';
import 'package:horeca_app/features/people/presentation/people_editors.dart';
import 'package:horeca_app/features/people/presentation/people_style.dart';

class SpecialtiesSection extends StatelessWidget {
  final PersonProfile profile;
  final bool isDark;
  const SpecialtiesSection({super.key, required this.profile, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colors = PeopleColors(isDark);
    final specialties = collectSpecialties(profile.workplaces, now: DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PeopleSectionHeader(title: 'Специальности', isDark: isDark),
        const SizedBox(height: 4),
        Text(
          'Каждая должность один раз. Полоска — сумма дней по всем местам этой должности.',
          style: TextStyle(color: colors.sub, height: 1.35),
        ),
        const SizedBox(height: 8),
        Text(
          experienceLegend(),
          key: const Key('experience-legend'),
          style: TextStyle(color: colors.text, fontSize: 13, height: 1.35, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (specialties.isEmpty)
          Text(
            'Добавьте место работы — должность станет специальностью.',
            style: TextStyle(color: colors.sub, height: 1.35),
          )
        else
          for (final item in specialties) ...[
            SpecialtyBar(item: item, isDark: isDark),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class WorkplacesSection extends ConsumerWidget {
  final PersonProfile profile;
  final bool isDark;
  const WorkplacesSection({super.key, required this.profile, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = PeopleColors(isDark);
    final owned = ref.watch(peopleRepositoryProvider).ownedVenues;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PeopleSectionHeader(
          title: 'Места работы',
          isDark: isDark,
          action: 'Добавить',
          onAction: () => editWorkplace(context, ref),
        ),
        Text(
          'Сколько угодно. Дата конца или отметка «работаю сейчас». В стаж идёт место, которое подтвердил владелец.',
          style: TextStyle(color: colors.sub, height: 1.35),
        ),
        const SizedBox(height: 10),
        if (profile.workplaces.isEmpty)
          Text('Мест работы пока нет. Добавьте место, чтобы пошёл стаж.',
              style: TextStyle(color: colors.sub))
        else
          for (final place in profile.workplaces) ...[
            WorkplaceTile(place: place, owned: owned, me: profile, isDark: isDark),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class SpecialtyBar extends StatelessWidget {
  final SpecialtyExperience item;
  final bool isDark;

  const SpecialtyBar({super.key, required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colors = PeopleColors(isDark);
    final color = experienceColor(item.level);
    final fill = experienceFill(item.totalDays);
    final days = item.totalDays <= 0 ? 'меньше дня' : countDays(item.totalDays);
    return Semantics(
      label: '${roleLabel(item.role)}, $days, ${experienceLevelLabel(item.level)}',
      child: Column(
        key: Key('specialty-${item.role.name}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  roleLabel(item.role),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.text),
                ),
              ),
              Text(
                experienceLevelLabel(item.level),
                style: TextStyle(fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${countPlaces(item.placeCount)} · $days',
            style: TextStyle(color: colors.sub, fontSize: 13),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 12,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: color.withOpacity(0.18)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fill,
                    child: ColoredBox(color: color),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WorkplaceTile extends ConsumerWidget {
  final WorkPlace place;
  final List<OwnedVenue> owned;
  final PersonProfile me;
  final bool isDark;

  const WorkplaceTile({
    super.key,
    required this.place,
    required this.owned,
    required this.me,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = PeopleColors(isDark);
    final period = place.workingNow
        ? 'с ${formatRuDate(place.startedAt)} · работаю сейчас'
        : '${formatRuDate(place.startedAt)} — ${formatRuDate(place.endedAt!)}';
    final canConfirm = canConfirmWorkplace(me: me, place: place, ownedVenues: owned);
    return PeopleCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.venueName,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.text)),
                    const SizedBox(height: 4),
                    Text('${roleLabel(place.role)} · $period',
                        style: TextStyle(color: colors.sub, height: 1.3)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Изменить',
                onPressed: () => editWorkplace(context, ref, current: place),
                icon: Icon(Icons.edit_outlined, color: colors.sub),
              ),
              IconButton(
                tooltip: 'Убрать',
                onPressed: () async {
                  final ok = await askPeopleConfirm(
                    context,
                    title: 'Убрать место?',
                    body: '«${place.venueName}» исчезнет из профиля. Специальности пересчитаются.',
                    confirm: 'Убрать',
                  );
                  if (!ok || !context.mounted) return;
                  ref.read(peopleRepositoryProvider.notifier).removeWorkplace(place.id);
                },
                icon: Icon(Icons.delete_outline_rounded, color: colors.sub),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (place.confirmed)
            const _StatusPill(text: 'Подтверждено', color: AppColors.green)
          else if (canConfirm)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  final error = ref.read(peopleRepositoryProvider.notifier).confirmWorkplace(place.id);
                  if (error != null) showPeopleMessage(context, error);
                },
                child: const Text('Подтвердить как владелец'),
              ),
            )
          else
            const _StatusPill(text: 'Ждёт подтверждения владельца', color: AppColors.muted),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}

