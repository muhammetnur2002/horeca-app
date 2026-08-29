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




