import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<String> copyPeopleFile(XFile file, String folder) async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/$folder');
  if (!await dir.exists()) await dir.create(recursive: true);
  final dot = file.name.lastIndexOf('.');
  var ext = dot >= 0 ? file.name.substring(dot + 1).toLowerCase() : 'bin';
  if (!RegExp(r'^[a-z0-9]{1,5}$').hasMatch(ext)) ext = 'bin';
  final saved = File('${dir.path}/${DateTime.now().microsecondsSinceEpoch}.$ext');
  try {
    await File(file.path).copy(saved.path);
  } catch (_) {
    await file.saveTo(saved.path);
  }
  return saved.path;
}

Future<void> deleteManagedPeopleFile(String? path) async {
  if (path == null || path.isEmpty) return;
  final normalized = path.replaceAll('\\', '/');
  final managed = normalized.contains('/people_photos/') || normalized.contains('/people_album/');
  if (!managed) return;
  final file = File(path);
  if (await file.exists()) await file.delete();
}

Future<int> localFileLength(String path) async {
  final file = File(path);
  if (!await file.exists()) return 0;
  return file.length();
}
