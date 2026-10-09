import 'dart:html' as html;

Future<String> saveDocumentBytes(String fileName, List<int> bytes) async {
  final blob = html.Blob([bytes]);
  return html.Url.createObjectUrlFromBlob(blob);
}
