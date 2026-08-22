// ignore_for_file: avoid_web_libraries_in_flutter
// Этот файл — веб-реализация PlatformSaver и подключается только через
// условный импорт в pdf_saver.dart (dart.library.html), т.е. попадает
// только в веб-сборку. Предупреждение линтера здесь — ложное срабатывание.
import 'dart:typed_data';
import 'dart:html' as html;

class PlatformSaver {
  static Future<void> save(Uint8List bytes, String fileName) async {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..target = 'blank'
      ..download = fileName
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
