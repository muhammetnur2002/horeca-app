import 'package:horeca_app/core/document_bytes_io.dart'
    if (dart.library.html) 'package:horeca_app/core/document_bytes_web.dart' as store;

Future<String> saveDocumentBytes(String fileName, List<int> bytes) =>
    store.saveDocumentBytes(fileName, bytes);
