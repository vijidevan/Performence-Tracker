import 'package:file_picker/file_picker.dart';

Future<PlatformFile?> pickStumpsPdf() {
  return FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );
}
