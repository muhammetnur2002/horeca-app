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
