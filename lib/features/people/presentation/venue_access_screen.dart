import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/people/data/people_repository.dart';
import 'package:horeca_app/features/people/domain/people_models.dart';
import 'package:horeca_app/features/people/presentation/people_style.dart';

/// Экран владельца. Допуск — отдельная запись, не личный профиль.
/// PIN администратора и сотрудника здесь не читается.
class VenueAccessScreen extends ConsumerStatefulWidget {
  const VenueAccessScreen({super.key});

  @override
  ConsumerState<VenueAccessScreen> createState() => _VenueAccessScreenState();
}

class _VenueAccessScreenState extends ConsumerState<VenueAccessScreen> {
  String? _selectedVenueId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = PeopleColors(isDark);
    final snapshot = ref.watch(peopleRepositoryProvider);
    final me = snapshot.me;
    final venues = snapshot.ownedVenues;
    final selectedStillThere = venues.any((venue) => venue.id == _selectedVenueId);
    final selectedId = selectedStillThere
        ? _selectedVenueId
        : (venues.isEmpty ? null : venues.first.id);
    final accesses = snapshot.accesses.where((access) => access.venueId == selectedId).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        foregroundColor: colors.text,
        iconTheme: IconThemeData(color: colors.text),
        title: Text(
          'Доступ к заведению',
          style: TextStyle(color: colors.text, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: PeopleBackground(isDark: isDark)),
          if (me == null)
            _NeedProfile(colors: colors)
          else
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  'Создаёт только владелец. Сотрудник не оформляет себе доступ в чужое заведение. У владельца свой профиль и свой ID.',
                  style: TextStyle(color: colors.text, fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 8),
                Text(
                  'Список не связан с PIN. Кнопки заявок, инвентаризации, смены и склада он пока не прячет.',
                  style: TextStyle(color: colors.sub, height: 1.35),
                ),
                const SizedBox(height: 16),
                PeopleCard(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Мой ID', style: TextStyle(color: colors.sub, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        me.id,
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(me.name, style: TextStyle(color: colors.sub)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                PeopleSectionHeader(
                  title: 'Мои заведения',
                  isDark: isDark,
                  action: 'Добавить',
                  onAction: () => _addVenue(context),
                ),
                Text(
                  'Заведение записывается на ваш ID. Это не код 01–05 из настроек Akyl.',
                  style: TextStyle(color: colors.sub, height: 1.35),
                ),
                const SizedBox(height: 10),
                if (venues.isEmpty)
                  Text(
                    'Пока пусто. После записи заведения можно выдавать доступ другим людям.',
                    style: TextStyle(color: colors.sub, height: 1.35),
                  )
                else
                  for (final venue in venues) ...[
                    PeopleCard(
                      isDark: isDark,
                      borderColor: venue.id == selectedId ? AppColors.orange : null,
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _selectedVenueId = venue.id),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  venue.name,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: colors.text,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Убрать заведение',
                            onPressed: () => _removeVenue(context, venue),
                            icon: Icon(Icons.delete_outline_rounded, color: colors.sub),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                const SizedBox(height: 18),
                PeopleSectionHeader(
                  title: 'Кому открыто',
                  isDark: isDark,
                  action: selectedId == null ? null : 'Выдать',
                  onAction: selectedId == null
                      ? null
                      : () => _openForm(context, venueId: selectedId),
                ),
                Text(
                  'Имя, должность на этом месте и разделы, которые человеку можно открывать. Личный профиль при этом не создаётся.',
                  style: TextStyle(color: colors.sub, height: 1.35),
                ),
                const SizedBox(height: 10),
                if (selectedId == null)
                  const SizedBox.shrink()
                else if (accesses.isEmpty)
                  Text('Допусков пока нет.', style: TextStyle(color: colors.sub))
                else
                  for (final access in accesses) ...[
                    _AccessCard(
                      access: access,
                      isDark: isDark,
                      onEdit: () => _openForm(context, venueId: access.venueId, current: access),
                      onDelete: () => _removeAccess(context, access),
                    ),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _addVenue(BuildContext context) async {
    final controller = TextEditingController();
    final colors = PeopleColors(Theme.of(context).brightness == Brightness.dark);
    final name = await showPeopleSheet<String>(
      context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Заведение на мой ID',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.text)),
            const SizedBox(height: 8),
            Text(
              'Так вы отмечаете, что выдаёте доступ как владелец.',
              style: TextStyle(color: colors.sub, height: 1.35),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: peopleField(colors, 'Название'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(sheetContext, controller.text),
              child: const Text('Записать'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (name == null || !context.mounted) return;
    final error = ref.read(peopleRepositoryProvider.notifier).addOwnedVenue(name);
    if (error != null) showPeopleMessage(context, error);
  }

  Future<void> _removeVenue(BuildContext context, OwnedVenue venue) async {
    final ok = await askPeopleConfirm(
      context,
      title: 'Убрать заведение?',
      body: '«${venue.name}» и выданные доступы этого места удалятся. Личные профили людей не изменятся.',
      confirm: 'Убрать',
    );
    if (!ok || !context.mounted) return;
    ref.read(peopleRepositoryProvider.notifier).removeOwnedVenue(venue.id);
  }

  Future<void> _removeAccess(BuildContext context, VenueAccess access) async {
    final ok = await askPeopleConfirm(
      context,
      title: 'Убрать доступ?',
      body: '${access.personName} больше не числится в допуске этого заведения. Личный профиль человека не меняется.',
      confirm: 'Убрать',
    );
    if (!ok || !context.mounted) return;
    ref.read(peopleRepositoryProvider.notifier).removeAccess(access.id);
  }

  Future<void> _openForm(
    BuildContext context, {
    required String venueId,
    VenueAccess? current,
  }) {
    return Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _AccessFormPage(venueId: venueId, current: current),
    ));
  }
}

class _NeedProfile extends StatelessWidget {
  final PeopleColors colors;
  const _NeedProfile({required this.colors});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Text(
          'Сначала личный профиль',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: colors.text),
        ),
        const SizedBox(height: 8),
        Text(
          'Владелец тоже человек общепита: у него свой ID. Вернитесь в «Люди» и создайте профиль, затем выдавайте доступ.',
          style: TextStyle(color: colors.sub, fontSize: 16, height: 1.4),
        ),
      ],
    );
  }
}

class _AccessCard extends StatelessWidget {
  final VenueAccess access;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AccessCard({
    required this.access,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PeopleColors(isDark);
    final sections = access.permissions.isEmpty
        ? 'Разделы не отмечены'
        : access.permissions.map(sectionLabel).join(', ');
    return PeopleCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  access.personName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colors.text),
                ),
              ),
              IconButton(
                tooltip: 'Изменить',
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined, color: colors.sub),
              ),
              IconButton(
                tooltip: 'Убрать',
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline_rounded, color: colors.sub),
              ),
            ],
          ),
          Text(roleLabel(access.position),
              style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(sections, style: TextStyle(color: colors.sub, height: 1.35)),
        ],
      ),
    );
  }
}

class _AccessFormPage extends ConsumerStatefulWidget {
  final String venueId;
  final VenueAccess? current;

  const _AccessFormPage({required this.venueId, required this.current});

  @override
  ConsumerState<_AccessFormPage> createState() => _AccessFormPageState();
}

class _AccessFormPageState extends ConsumerState<_AccessFormPage> {
  late final TextEditingController _name;
  late HospitalityRole _role;
  late final Set<VenueSection> _sections;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    _name = TextEditingController(text: current?.personName ?? '');
    _role = current?.position ?? HospitalityRole.waiter;
    _sections = {...?current?.permissions};
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final repo = ref.read(peopleRepositoryProvider.notifier);
    final sections = VenueSection.values.where(_sections.contains).toList();
    final error = widget.current == null
        ? repo.createAccess(
            venueId: widget.venueId,
            personName: _name.text,
            position: _role,
            permissions: sections,
          )
        : repo.updateAccess(
            accessId: widget.current!.id,
            personName: _name.text,
            position: _role,
            permissions: sections,
          );
    if (error != null) {
      showPeopleMessage(context, error);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = PeopleColors(isDark);
    final matches = ref
        .watch(peopleRepositoryProvider)
        .ownedVenues
        .where((venue) => venue.id == widget.venueId);
    final venueName = matches.isEmpty ? null : matches.first.name;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        foregroundColor: colors.text,
        iconTheme: IconThemeData(color: colors.text),
        title: Text(
          widget.current == null ? 'Выдать доступ' : 'Изменить доступ',
          style: TextStyle(color: colors.text, fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: PeopleBackground(isDark: isDark)),
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              if (venueName != null)
                Text(venueName, style: TextStyle(color: colors.sub, fontSize: 15)),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: colors.text, fontSize: 18),
                decoration: peopleField(colors, 'Имя человека'),
              ),
              const SizedBox(height: 8),
              Text(
                'Человек заводит личный профиль сам. Здесь только имя для допуска.',
                style: TextStyle(color: colors.sub, height: 1.35),
              ),
              const SizedBox(height: 16),
              Text('Должность на этом месте',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: colors.text)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final role in HospitalityRole.values)
                    ChoiceChip(
                      label: Text(roleLabel(role)),
                      selected: _role == role,
                      selectedColor: AppColors.orange,
                      labelStyle: TextStyle(
                        color: _role == role ? Colors.white : colors.text,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setState(() => _role = role),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Что можно открывать',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: colors.text)),
              const SizedBox(height: 4),
              for (final section in VenueSection.values)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _sections.contains(section),
                  activeColor: AppColors.orange,
                  title: Text(sectionLabel(section), style: TextStyle(color: colors.text)),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _sections.add(section);
                      } else {
                        _sections.remove(section);
                      }
                    });
                  },
                ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _save,
                child: Text(widget.current == null ? 'Выдать доступ' : 'Сохранить'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
