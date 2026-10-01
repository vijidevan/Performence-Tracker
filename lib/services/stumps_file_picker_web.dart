import 'package:file_picker/file_picker.dart';
import 'package:file_picker_web/file_picker_web.dart';

Future<PlatformFile?> pickStumpsPdf() {
  return FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
    webOptions: const FilePickerWebOptions(
      cancelUploadOnWindowBlur: false,
    ),
  );
}
