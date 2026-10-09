import 'package:image_picker/image_picker.dart';
import 'package:horeca_app/features/people/presentation/people_files_io.dart'
    if (dart.library.html) 'package:horeca_app/features/people/presentation/people_files_web.dart'
    as files;

Future<String> copyPeopleFile(XFile file, String folder) =>
    files.copyPeopleFile(file, folder);

Future<void> deleteManagedPeopleFile(String? path) =>
    files.deleteManagedPeopleFile(path);

Future<int> localFileLength(String path) => files.localFileLength(path);
