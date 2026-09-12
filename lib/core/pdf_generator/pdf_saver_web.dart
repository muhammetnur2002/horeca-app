import 'dart:typed_data';
// Файл подключается только для web через условный импорт в pdf_saver.dart.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class PlatformSaver {
  static Future<void> save(Uint8List bytes, String fileName) async {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..target = 'blank'
      ..download = fileName
      ..click();
    // Даём браузеру подхватить blob до отзыва ссылки.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    html.Url.revokeObjectUrl(url);
  }
}




