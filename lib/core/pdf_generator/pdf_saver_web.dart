import 'dart:typed_data';

// universal_html вместо dart:html: на вебе это тот же самый API, но
// анализатор не ругается на web-only библиотеку в обычном Flutter-коде,
// а сам dart:html объявлен устаревшим.
import 'package:universal_html/html.dart' as html;

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
