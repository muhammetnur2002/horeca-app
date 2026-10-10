// ignore_for_file: avoid_web_libraries_in_flutter
// Веб-реализация, подключается только условным импортом (dart.library.html),
// т.е. попадает только в веб-сборку. Предупреждение линтера здесь ложное.
import 'dart:convert';
import 'dart:html' as html;

import 'package:image_picker/image_picker.dart';

final _sizes = <String, int>{};

/// Фото хранится как data:-ссылка: она переживает перезагрузку страницы.
/// Ссылка blob: умирала после F5, и вместо фото оставалась заглушка.
Future<String> copyPeopleFile(XFile file, String folder) async {
  final bytes = await file.readAsBytes();
  final mime = file.mimeType ?? _mimeFromName(file.name);
  if (mime.startsWith('image/')) {
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  _sizes[url] = bytes.length;
  return url;
}

Future<void> deleteManagedPeopleFile(String? path) async {
  if (path == null || !path.startsWith('blob:')) return;
  html.Url.revokeObjectUrl(path);
  _sizes.remove(path);
}

Future<int> localFileLength(String path) async {
  if (path.startsWith('data:')) {
    final comma = path.indexOf(',');
    return comma < 0 ? 0 : (path.length - comma - 1) * 3 ~/ 4;
  }
  return _sizes[path] ?? 0;
}

String _mimeFromName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.heic')) {
    return 'image/jpeg';
  }
  return 'application/octet-stream';
}
