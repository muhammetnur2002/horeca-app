import 'package:flutter/material.dart';
import 'package:horeca_app/core/local_media.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/landing/data/door_repository.dart';
import 'package:horeca_app/features/people/data/people_repository.dart';
import 'package:horeca_app/features/people/domain/people_calc.dart';
import 'package:horeca_app/features/people/domain/people_models.dart';
import 'package:horeca_app/features/people/presentation/album_pages.dart';
import 'package:horeca_app/features/people/presentation/people_editors.dart';
import 'package:horeca_app/features/people/presentation/people_media.dart';
import 'package:horeca_app/features/people/presentation/people_style.dart';
import 'package:horeca_app/features/people/presentation/people_work_sections.dart';

class PeopleProfileScreen extends ConsumerWidget {
  const PeopleProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = PeopleColors(isDark);
    final me = ref.watch(peopleRepositoryProvider).me;
    final staffDoor = ref.watch(doorProvider) == AppDoor.staff;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        foregroundColor: colors.text,
        iconTheme: IconThemeData(color: colors.text),
        title: Text('Профиль сотрудника', style: TextStyle(color: colors.text, fontWeight: FontWeight.w700)),
        actions: [
          if (staffDoor)
            IconButton(
              tooltip: 'Сменить вход',
              onPressed: () => ref.read(doorProvider.notifier).reset(),
              icon: const Icon(Icons.swap_horiz_rounded),
            )
          else if (me != null)
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
    final main = specialties.isEmpty
        ? null
        : (specialties.toList()..sort((a, b) => b.totalDays.compareTo(a.totalDays))).first;
    final steps = PersonRank.values.length - 1;
    final barColor = main == null ? AppColors.orange : experienceColor(main.level);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
      children: [
        // Шапка по макету: фото в оранжевом кольце, справа имя, ID и ранг.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(profile: profile, size: 124, onTap: () => chooseProfilePhoto(context, ref)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(
                        profile.name,
                        style: TextStyle(
                            fontSize: 23, height: 1.15, fontWeight: FontWeight.w800, color: colors.text),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Изменить имя',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => editPersonName(context, ref),
                      icon: Icon(Icons.edit_outlined, size: 18, color: colors.sub),
                    ),
                  ]),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: profile.id));
                      if (context.mounted) showPeopleMessage(context, 'ID скопирован');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        const Icon(Icons.badge_outlined, size: 16, color: AppColors.orange),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            profile.id,
                            key: const Key('person-id'),
                            style: TextStyle(
                              color: colors.sub,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.orange.withOpacity(0.07),
                      border: Border.all(color: AppColors.orange.withOpacity(0.45)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.military_tech_outlined, color: AppColors.orange, size: 30),
                      const SizedBox(width: 10),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Ранг', style: TextStyle(color: colors.sub, fontSize: 12)),
                        Text(
                          rank.title,
                          key: const Key('person-rank-title'),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.orange),
                        ),
                      ]),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(children: [
          Icon(Icons.restaurant_menu_rounded, color: colors.text, size: 28),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Специальность', style: TextStyle(color: colors.sub, fontSize: 12)),
            Text(
              main == null ? 'добавьте место работы' : roleLabel(main.role),
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colors.text),
            ),
          ]),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Text('Опыт', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.text)),
          const Spacer(),
          Text('${rank.rank.index} / $steps',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.text)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 8,
            child: Stack(fit: StackFit.expand, children: [
              ColoredBox(color: colors.text.withOpacity(0.12)),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (rank.rank.index / steps).clamp(0.04, 1.0),
                child: ColoredBox(color: barColor),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Text(rank.reason, style: TextStyle(fontSize: 13, height: 1.35, color: colors.sub)),
        const SizedBox(height: 4),
        Text(rankScaleCaption(), style: TextStyle(fontSize: 12, height: 1.35, color: colors.sub)),
        const SizedBox(height: 14),
        Divider(color: colors.text.withOpacity(0.08)),
        const SizedBox(height: 6),
        PeopleSectionHeader(
          title: 'Фотоальбом',
          isDark: isDark,
          action: profile.album.isEmpty ? 'Добавить' : 'Смотреть все',
          onAction: () => profile.album.isEmpty
              ? chooseAlbumSource(context, ref)
              : Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _AlbumPage())),
        ),
        const SizedBox(height: 8),
        if (profile.album.isEmpty)
          Text(
            'Альбом пуст. Фото и видео о работе: кухня, бар, зал, блюдо, команда.',
            style: TextStyle(color: colors.sub, height: 1.35),
          )
        else
          _AlbumGrid(items: profile.album.take(6).toList()),
        const SizedBox(height: 22),
        SpecialtiesSection(profile: profile, isDark: isDark),
        const SizedBox(height: 10),
        WorkplacesSection(profile: profile, isDark: isDark),
        const SizedBox(height: 18),
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
      ],
    );
  }
}

class _AlbumGrid extends StatelessWidget {
  final List<AlbumItem> items;
  const _AlbumGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _AlbumTile(item: items[index]),
    );
  }
}

/// «Смотреть все»: весь альбом и добавление.
class _AlbumPage extends ConsumerWidget {
  const _AlbumPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = PeopleColors(isDark);
    final album = ref.watch(peopleRepositoryProvider).me?.album ?? const <AlbumItem>[];
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        foregroundColor: colors.text,
        title: Text('Фотоальбом · ${album.length}',
            style: TextStyle(color: colors.text, fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        onPressed: () => chooseAlbumSource(context, ref),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Добавить'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Text(
            'Только фото и видео про общепит. Видео больше 50 МБ приложение не возьмёт.',
            style: TextStyle(color: colors.sub, height: 1.35),
          ),
          const SizedBox(height: 12),
          _AlbumGrid(items: album),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final PersonProfile profile;
  final VoidCallback onTap;
  final double size;

  const _Avatar({required this.profile, required this.onTap, this.size = 176});

  @override
  Widget build(BuildContext context) {
    final path = profile.photoPath;
    final hasFile = path != null && localPathExists(path);
    final letter = profile.name.isEmpty ? '?' : profile.name.substring(0, 1).toUpperCase();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.orange, width: 3),
          boxShadow: [BoxShadow(color: AppColors.orange.withOpacity(0.3), blurRadius: 20)],
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
