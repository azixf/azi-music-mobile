import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';

class Picker {
  static Future<String> selectFolder(
      {required BuildContext context, String? message}) async {
    final String? temp =
        await FilePicker.platform.getDirectoryPath(dialogTitle: message);
    return (temp == '/' || temp == null) ? '' : temp;
  }

  static Future<String> selectFile(
      {required BuildContext context, String? message}) async {
    final FilePickerResult? result =
        await FilePicker.platform.pickFiles(dialogTitle: message);

    if (result != null) {
      final File file = File(result.files.first.path!);
      return file.path == '/' ? '' : file.path;
    }
    return '';
  }
}
