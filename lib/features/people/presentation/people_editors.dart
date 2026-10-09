import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/people/data/people_repository.dart';
import 'package:horeca_app/features/people/domain/people_models.dart';
import 'package:horeca_app/features/people/presentation/people_media.dart';
import 'package:horeca_app/features/people/presentation/people_style.dart';

Future<void> editPersonName(BuildContext context, WidgetRef ref) async {
  final current = ref.read(peopleRepositoryProvider).me?.name ?? '';
  final controller = TextEditingController(text: current);
  await showPeopleSheet<void>(
    context,
    builder: (sheetContext) {
      final colors = PeopleColors(Theme.of(sheetContext).brightness == Brightness.dark);
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Изменить имя',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.text)),
            const SizedBox(height: 8),
            Text('ID от имени не зависит.', style: TextStyle(color: colors.sub)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: peopleField(colors, 'Имя'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final error = ref.read(peopleRepositoryProvider.notifier).rename(controller.text);
                if (error != null) {
                  showPeopleMessage(sheetContext, error);
                  return;
                }
                Navigator.pop(sheetContext);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      );
    },
  );
  controller.dispose();
}

Future<void> chooseProfilePhoto(BuildContext context, WidgetRef ref) async {
  final hasPhoto = ref.read(peopleRepositoryProvider).me?.photoPath != null;
  await showPeopleSheet<void>(
    context,
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.photo_library_outlined, color: AppColors.orange),
          title: const Text('Выбрать из галереи'),
          onTap: () {
            Navigator.pop(sheetContext);
            pickProfilePhoto(context, ref, ImageSource.gallery);
          },
        ),
        ListTile(
          leading: const Icon(Icons.photo_camera_outlined, color: AppColors.orange),
          title: const Text('Сделать снимок'),
          onTap: () {
            Navigator.pop(sheetContext);
            pickProfilePhoto(context, ref, ImageSource.camera);
          },
        ),
        if (hasPhoto)
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            title: const Text('Убрать фото'),
            onTap: () {
              Navigator.pop(sheetContext);
              clearProfilePhoto(context, ref);
            },
          ),
        const SizedBox(height: 8),
      ],
    ),
  );
}

Future<void> addSkill(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  await showPeopleSheet<void>(
    context,
    builder: (sheetContext) {
      final colors = PeopleColors(Theme.of(sheetContext).brightness == Brightness.dark);
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Навык', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.text)),
            const SizedBox(height: 8),
            Text('Повтор не добавится.', style: TextStyle(color: colors.sub)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: peopleField(colors, 'Например, латте-арт'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final error = ref.read(peopleRepositoryProvider.notifier).addSkill(controller.text);
                if (error != null) {
                  showPeopleMessage(sheetContext, error);
                  return;
                }
                Navigator.pop(sheetContext);
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      );
    },
  );
  controller.dispose();
}

Future<void> addAward(BuildContext context, WidgetRef ref) async {
  final title = TextEditingController();
  final note = TextEditingController();
  await showPeopleSheet<void>(
    context,
    builder: (sheetContext) {
      final colors = PeopleColors(Theme.of(sheetContext).brightness == Brightness.dark);
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Награда', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.text)),
            const SizedBox(height: 16),
            TextField(
              controller: title,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: peopleField(colors, 'Название'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              textCapitalization: TextCapitalization.sentences,
              decoration: peopleField(colors, 'Коротко, если нужно'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final error = ref.read(peopleRepositoryProvider.notifier).addAward(title.text, note.text);
                if (error != null) {
                  showPeopleMessage(sheetContext, error);
                  return;
                }
                Navigator.pop(sheetContext);
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      );
    },
  );
  title.dispose();
  note.dispose();
}

Future<void> chooseAlbumSource(BuildContext context, WidgetRef ref) async {
  await showPeopleSheet<void>(
    context,
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        const ListTile(
          title: Text('Альбом про общепит'),
          subtitle: Text('Фото и видео с кухни, бара, зала и смены. Видео до 50 МБ.'),
        ),
        ListTile(
          leading: const Icon(Icons.photo_outlined, color: AppColors.orange),
          title: const Text('Добавить фото'),
          onTap: () {
            Navigator.pop(sheetContext);
            pickAlbumMedia(context, ref, AlbumKind.photo);
          },
        ),
        ListTile(
          leading: const Icon(Icons.videocam_outlined, color: AppColors.orange),
          title: const Text('Добавить видео'),
          subtitle: const Text('Ролик больше 50 МБ не сохранится'),
          onTap: () {
            Navigator.pop(sheetContext);
            pickAlbumMedia(context, ref, AlbumKind.video);
          },
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
}

Future<void> editWorkplace(BuildContext context, WidgetRef ref, {WorkPlace? current}) {
  return showPeopleSheet<void>(
    context,
    builder: (sheetContext) => _WorkplaceSheet(current: current),
  );
}

class _WorkplaceSheet extends ConsumerStatefulWidget {
  final WorkPlace? current;
  const _WorkplaceSheet({required this.current});

  @override
  ConsumerState<_WorkplaceSheet> createState() => _WorkplaceSheetState();
}

class _WorkplaceSheetState extends ConsumerState<_WorkplaceSheet> {
  late final TextEditingController _name;
  late HospitalityRole _role;
  late DateTime _started;
  DateTime? _ended;
  late bool _workingNow;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    _name = TextEditingController(text: current?.venueName ?? '');
    _role = current?.role ?? HospitalityRole.waiter;
    _started = current?.startedAt ?? dateOnly(DateTime.now());
    _ended = current?.endedAt;
    _workingNow = current == null || current.workingNow;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _started,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
      helpText: 'Дата начала',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
    );
    if (picked == null) return;
    setState(() => _started = dateOnly(picked));
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _ended ?? _started,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
      helpText: 'Дата конца',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
    );
    if (picked == null) return;
    setState(() => _ended = dateOnly(picked));
  }

  void _save() {
    final ended = _workingNow ? null : _ended;
    if (!_workingNow && ended == null) {
      showPeopleMessage(context, 'Укажите дату конца или включите «Работаю сейчас».');
      return;
    }
    final repo = ref.read(peopleRepositoryProvider.notifier);
    final error = repo.workplaceValidationError(
      venueName: _name.text,
      startedAt: _started,
      endedAt: ended,
    );
    if (error != null) {
      showPeopleMessage(context, error);
      return;
    }
    final current = widget.current;
    if (current == null) {
      final addError = repo.addWorkplace(
        venueName: _name.text,
        role: _role,
        startedAt: _started,
        endedAt: ended,
      );
      if (addError != null) {
        showPeopleMessage(context, addError);
        return;
      }
    } else {
      final wasConfirmed = current.confirmed;
      final cleared = repo.updateWorkplace(
        id: current.id,
        venueName: _name.text,
        role: _role,
        startedAt: _started,
        endedAt: ended,
      );
      if (wasConfirmed && cleared) {
        showPeopleMessage(
          context,
          'Место изменено. Подтверждение снято: его снова ставит владелец.',
        );
      }
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = PeopleColors(Theme.of(context).brightness == Brightness.dark);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.current == null ? 'Место работы' : 'Изменить место',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.text),
          ),
          const SizedBox(height: 8),
          Text(
            'Должность попадёт в специальности. Одинаковые должности на экране не повторяются.',
            style: TextStyle(color: colors.sub, height: 1.35),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: peopleField(colors, 'Название места'),
          ),
          const SizedBox(height: 14),
          Text('Должность', style: TextStyle(fontWeight: FontWeight.w700, color: colors.text)),
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
          const SizedBox(height: 14),
          _DateButton(
            label: 'Начало',
            value: formatRuDate(_started),
            onTap: _pickStart,
            colors: colors,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Работаю сейчас', style: TextStyle(color: colors.text)),
            value: _workingNow,
            activeColor: AppColors.orange,
            onChanged: (value) => setState(() => _workingNow = value),
          ),
          if (!_workingNow)
            _DateButton(
              label: 'Конец',
              value: _ended == null ? 'Выберите дату' : formatRuDate(_ended!),
              onTap: _pickEnd,
              colors: colors,
            ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _save, child: const Text('Сохранить')),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final PeopleColors colors;

  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.field,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: colors.sub)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.text)),
                ],
              ),
            ),
            Icon(Icons.calendar_today_rounded, color: colors.sub, size: 18),
          ],
        ),
      ),
    );
  }
}
