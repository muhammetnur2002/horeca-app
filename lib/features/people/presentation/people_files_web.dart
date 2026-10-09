// ignore_for_file: avoid_web_libraries_in_flutter
// Веб-реализация, подключается только условным импортом (dart.library.html),
// т.е. попадает только в веб-сборку. Предупреждение линтера здесь ложное.
import 'dart:html' as html;

import 'package:image_picker/image_picker.dart';

final _sizes = <String, int>{};

Future<String> copyPeopleFile(XFile file, String folder) async {
  final bytes = await file.readAsBytes();
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

Future<int> localFileLength(String path) async => _sizes[path] ?? 0;
