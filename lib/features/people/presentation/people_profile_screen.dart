import 'package:flutter/material.dart';
import 'package:horeca_app/core/local_media.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/people/data/people_repository.dart';
import 'package:horeca_app/features/people/domain/people_calc.dart';
import 'package:horeca_app/features/people/domain/people_models.dart';
import 'package:horeca_app/features/people/presentation/album_pages.dart';
import 'package:horeca_app/features/people/presentation/people_editors.dart';
import 'package:horeca_app/features/people/presentation/people_media.dart';
import 'package:horeca_app/features/people/presentation/people_style.dart';

class PeopleProfileScreen extends ConsumerWidget {
  const PeopleProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = PeopleColors(isDark);
    final me = ref.watch(peopleRepositoryProvider).me;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        foregroundColor: colors.text,
        iconTheme: IconThemeData(color: colors.text),
        title: Text('Люди', style: TextStyle(color: colors.text, fontWeight: FontWeight.w700)),
        actions: [
          if (me != null)
            TextButton(
              onPressed: () => context.push('/people/access'),
              child: const Text('Доступ', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: PeopleBackground(isDark: isDark)),
          me == null
              ? const _CreateProfile()
              : _ProfileBody(profile: me, isDark: isDark),
        ],
      ),
    );
  }
}

class _CreateProfile extends ConsumerStatefulWidget {
  const _CreateProfile();

  @override
  ConsumerState<_CreateProfile> createState() => _CreateProfileState();
}

class _CreateProfileState extends ConsumerState<_CreateProfile> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _create() {
    final error = ref.read(peopleRepositoryProvider.notifier).createProfile(_name.text);
    if (error != null && mounted) showPeopleMessage(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final colors = PeopleColors(Theme.of(context).brightness == Brightness.dark);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text(
          'Личный профиль',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: colors.text, height: 1.1),
        ),
        const SizedBox(height: 8),
        Text(
          'Его заводите вы сами. ID останется с вами, когда смените место работы. Это не PIN сотрудника и не вход администратора.',
          style: TextStyle(fontSize: 15, height: 1.4, color: colors.sub),
        ),
        const SizedBox(height: 20),
        PeopleCard(
          isDark: colors.isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: colors.text, fontSize: 18),
                decoration: peopleField(colors, 'Имя'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _create,
                child: const Text('Создать профиль и получить ID'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Фото, специальности, места и альбом появятся на следующем экране. Допуск в заведение выдаёт владелец отдельно.',
          style: TextStyle(color: colors.sub, height: 1.35),
        ),
      ],
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final PersonProfile profile;
  final bool isDark;

  const _ProfileBody({required this.profile, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = PeopleColors(isDark);
    final now = DateTime.now();
    final rank = assessRank(profile.workplaces, now: now);
    final specialties = collectSpecialties(profile.workplaces, now: now);
    final owned = ref.watch(peopleRepositoryProvider).ownedVenues;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Center(child: _Avatar(profile: profile, onTap: () => chooseProfilePhoto(context, ref))),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                profile.name,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: colors.text),
              ),
            ),
            IconButton(
              tooltip: 'Изменить имя',
              onPressed: () => editPersonName(context, ref),
              icon: Icon(Icons.edit_outlined, color: colors.sub),
            ),
          ],
        ),
        const SizedBox(height: 8),
        PeopleCard(
          isDark: isDark,
          child: InkWell(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: profile.id));
              if (context.mounted) showPeopleMessage(context, 'ID скопирован');
            },
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Постоянный ID', style: TextStyle(color: colors.sub, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        profile.id,
                        key: const Key('person-id'),
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.copy_rounded, color: colors.sub),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Хранится на этом телефоне. Облако для профилей подключим отдельно, офлайн-работа Akyl от этого не зависит.',
          style: TextStyle(color: colors.sub, fontSize: 12, height: 1.35),
        ),
        const SizedBox(height: 18),
        PeopleCard(
          isDark: isDark,
          borderColor: AppColors.orange.withOpacity(0.45),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Рейтинг', style: TextStyle(color: colors.sub, fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                rank.title,
                key: const Key('person-rank-title'),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.orange,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Text(rank.reason, style: TextStyle(fontSize: 16, height: 1.35, color: colors.text)),
              const SizedBox(height: 8),
              Text(rankScaleCaption(), style: TextStyle(fontSize: 12, height: 1.35, color: colors.sub)),
            ],
          ),
        ),
        const SizedBox(height: 22),
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
            _SpecialtyBar(item: item, isDark: isDark),
            const SizedBox(height: 12),
          ],
        const SizedBox(height: 10),
        PeopleSectionHeader(
          title: 'Навыки',
          isDark: isDark,
          action: 'Добавить',
          onAction: () => addSkill(context, ref),
        ),
        if (profile.skills.isEmpty)
          Text('Пока пусто.', style: TextStyle(color: colors.sub))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final skill in profile.skills)
                InputChip(
                  label: Text(skill),
                  onDeleted: () => ref.read(peopleRepositoryProvider.notifier).removeSkill(skill),
                ),
            ],
          ),
        const SizedBox(height: 18),
        PeopleSectionHeader(
          title: 'Награды',
          isDark: isDark,
          action: 'Добавить',
          onAction: () => addAward(context, ref),
        ),
        if (profile.awards.isEmpty)
          Text('Пока пусто.', style: TextStyle(color: colors.sub))
        else
          for (final award in profile.awards) ...[
            PeopleCard(
              isDark: isDark,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.emoji_events_outlined, color: AppColors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(award.title,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: colors.text)),
                        if (award.note.isNotEmpty)
                          Text(award.note, style: TextStyle(color: colors.sub, height: 1.3)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Убрать награду',
                    onPressed: () async {
                      final ok = await askPeopleConfirm(
                        context,
                        title: 'Убрать награду?',
                        body: award.title,
                        confirm: 'Убрать',
                      );
                      if (!ok || !context.mounted) return;
                      ref.read(peopleRepositoryProvider.notifier).removeAward(award.id);
                    },
                    icon: Icon(Icons.close_rounded, color: colors.sub),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 10),
        PeopleSectionHeader(
          title: 'Места работы',
          isDark: isDark,
          action: 'Добавить',
          onAction: () => editWorkplace(context, ref),
        ),
        Text(
          'Сколько угодно. Дата конца или отметка «работаю сейчас».',
          style: TextStyle(color: colors.sub, height: 1.35),
        ),
        const SizedBox(height: 10),
        if (profile.workplaces.isEmpty)
          Text('Мест пока нет.', style: TextStyle(color: colors.sub))
        else
          for (final place in profile.workplaces) ...[
            _WorkplaceTile(place: place, owned: owned, me: profile, isDark: isDark),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 10),
        PeopleSectionHeader(
          title: 'Альбом',
          isDark: isDark,
          action: 'Добавить',
          onAction: () => chooseAlbumSource(context, ref),
        ),
        Text(
          'Только фото и видео про общепит. Видео больше 50 МБ приложение не возьмёт.',
          style: TextStyle(color: colors.sub, height: 1.35),
        ),
        const SizedBox(height: 10),
        if (profile.album.isEmpty)
          Text('Альбом пуст.', style: TextStyle(color: colors.sub))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: profile.album.length,
            itemBuilder: (context, index) {
              final item = profile.album[index];
              return _AlbumTile(item: item);
            },
          ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final PersonProfile profile;
  final VoidCallback onTap;

  const _Avatar({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final path = profile.photoPath;
    final hasFile = path != null && localPathExists(path);
    final letter = profile.name.isEmpty ? '?' : profile.name.substring(0, 1).toUpperCase();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 176,
        height: 176,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.orange, width: 3),
          color: AppColors.orange.withOpacity(0.16),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasFile
            ? localImage(path, missing: _letter(letter))
            : _letter(letter),
      ),
    );
  }

  Widget _letter(String letter) {
    return Center(
      child: Text(
        letter,
        style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w800, color: AppColors.orange),
      ),
    );
  }
}

class _SpecialtyBar extends StatelessWidget {
  final SpecialtyExperience item;
  final bool isDark;

  const _SpecialtyBar({required this.item, required this.isDark});

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

class _WorkplaceTile extends ConsumerWidget {
  final WorkPlace place;
  final List<OwnedVenue> owned;
  final PersonProfile me;
  final bool isDark;

  const _WorkplaceTile({
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

class _AlbumTile extends ConsumerWidget {
  final AlbumItem item;
  const _AlbumTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exists = localPathExists(item.localPath);
    return GestureDetector(
      onTap: () {
        final repo = ref.read(peopleRepositoryProvider.notifier);
        void remove() {
          repo.removeAlbumItem(item.id);
          deleteManagedPeopleFile(item.localPath);
        }

        if (item.kind == AlbumKind.video) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => AlbumVideoPage(path: item.localPath, onDelete: remove),
          ));
          return;
        }
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AlbumPhotoPage(path: item.localPath, onDelete: remove),
        ));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.kind == AlbumKind.photo && exists)
              localImage(item.localPath, missing: const _MissingMedia())
            else
              const ColoredBox(color: Color(0xFF1A1A2E)),
            if (item.kind == AlbumKind.video)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 36),
                  const SizedBox(height: 4),
                  Text(
                    formatBytes(item.sizeBytes),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MissingMedia extends StatelessWidget {
  const _MissingMedia();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF2E3352),
      child: Icon(Icons.broken_image_outlined, color: Colors.white70),
    );
  }
}
