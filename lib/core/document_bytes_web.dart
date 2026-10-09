// ignore_for_file: avoid_web_libraries_in_flutter
// Веб-реализация, подключается только условным импортом (dart.library.html),
// т.е. попадает только в веб-сборку. Предупреждение линтера здесь ложное.
import 'dart:html' as html;

Future<String> saveDocumentBytes(String fileName, List<int> bytes) async {
  final blob = html.Blob([bytes]);
  return html.Url.createObjectUrlFromBlob(blob);
}
