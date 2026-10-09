import 'dart:typed_data';
import 'pdf_saver_mobile.dart' if (dart.library.html) 'pdf_saver_web.dart';

Future<void> saveFile(
  Uint8List bytes,
  String fileName, {
  String mimeType = 'application/pdf',
}) =>
    PlatformSaver.save(bytes, fileName, mimeType);
