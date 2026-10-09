import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:horeca_app/features/people/presentation/people_files.dart';

export 'package:horeca_app/features/people/presentation/people_files.dart';
import 'package:horeca_app/features/people/data/people_repository.dart';
import 'package:horeca_app/features/people/domain/people_calc.dart';
import 'package:horeca_app/features/people/domain/people_models.dart';
import 'package:horeca_app/features/people/presentation/people_style.dart';

Future<bool> askHorecaMedia(BuildContext context) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final colors = PeopleColors(isDark);
  final answer = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: colors.sheet,
      title: Text(AlbumLimits.horecaOnlyTitle, style: TextStyle(color: colors.text)),
      content: Text(AlbumLimits.horecaOnlyBody, style: TextStyle(color: colors.sub, height: 1.35)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(AlbumLimits.horecaCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(AlbumLimits.horecaConfirm),
        ),
      ],
    ),
  );
  return answer == true;
}

Future<void> pickProfilePhoto(BuildContext context, WidgetRef ref, ImageSource source) async {
  final XFile? picked;
  try {
    picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
  } catch (_) {
    if (context.mounted) {
      showPeopleMessage(context, 'Не удалось открыть фото. Проверьте доступ к камере или галерее.');
    }
    return;
  }
  if (picked == null || !context.mounted) return;
  await _replaceProfilePhoto(context, ref, picked);
}

Future<void> _replaceProfilePhoto(BuildContext context, WidgetRef ref, XFile picked) async {
  final previous = ref.read(peopleRepositoryProvider).me?.photoPath;
  final String saved;
  try {
    saved = await copyPeopleFile(picked, 'people_photos');
  } catch (_) {
    if (context.mounted) showPeopleMessage(context, 'Не удалось сохранить фото на телефон.');
    return;
  }
  ref.read(peopleRepositoryProvider.notifier).setPhotoPath(saved);
  await deleteManagedPeopleFile(previous);
}

Future<void> clearProfilePhoto(BuildContext context, WidgetRef ref) async {
  final previous = ref.read(peopleRepositoryProvider).me?.photoPath;
  ref.read(peopleRepositoryProvider.notifier).setPhotoPath(null);
  await deleteManagedPeopleFile(previous);
}

Future<void> pickAlbumMedia(BuildContext context, WidgetRef ref, AlbumKind kind) async {
  final XFile? picked;
  try {
    final picker = ImagePicker();
    picked = kind == AlbumKind.photo
        ? await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 2000)
        : await picker.pickVideo(source: ImageSource.gallery);
  } catch (_) {
    if (context.mounted) {
      showPeopleMessage(context, 'Не удалось открыть галерею.');
    }
    return;
  }
  if (picked == null || !context.mounted) return;

  int? size;
  try {
    size = await picked.length();
  } catch (_) {
    size = null;
  }
  if (!context.mounted) return;

  // Размер видео проверяется до копирования в память приложения.
  if (kind == AlbumKind.video) {
    final decision = decideVideoUpload(size);
    if (!decision.allowed) {
      showPeopleMessage(context, decision.message ?? AlbumLimits.videoTooLargeText);
      return;
    }
  }

  final agreed = await askHorecaMedia(context);
  if (!agreed || !context.mounted) return;

  final String saved;
  try {
    saved = await copyPeopleFile(picked, 'people_album');
  } catch (_) {
    if (context.mounted) showPeopleMessage(context, 'Не удалось сохранить файл на телефон.');
    return;
  }

  var storedSize = size ?? 0;
  try {
    storedSize = await localFileLength(saved);
  } catch (_) {
    storedSize = size ?? -1;
  }
  if (kind == AlbumKind.video) {
    final again = decideVideoUpload(storedSize);
    if (!again.allowed) {
      await deleteManagedPeopleFile(saved);
      if (context.mounted) {
        showPeopleMessage(context, again.message ?? AlbumLimits.videoTooLargeText);
      }
      return;
    }
  }
  if (!context.mounted) return;
  final error = ref.read(peopleRepositoryProvider.notifier).addAlbumItem(
        kind: kind,
        localPath: saved,
        sizeBytes: storedSize,
      );
  if (error != null) {
    await deleteManagedPeopleFile(saved);
    if (context.mounted) showPeopleMessage(context, error);
  }
}
