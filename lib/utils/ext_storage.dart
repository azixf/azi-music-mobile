import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ExtStroageProvider {
  // ask for permission
  static Future<bool> requestPermission(Permission permission) async {
    if (await permission.isGranted) return true;
    final result = await permission.request();
    if (result == PermissionStatus.granted) return true;
    return false;
  }

  static Future<String> getExtrStorge({required String dirname}) async {
    Directory? directory;

    try {
      if (Platform.isAndroid) {
        if (await requestPermission(Permission.storage)) {
          directory = await getExternalStorageDirectory();

          final String newPath = directory!.path.replaceFirst(
              'Android/data/com.example.azi_music_mobile/files', dirname);
          directory = Directory(newPath);

          if (!await directory.exists()) {
            await requestPermission(Permission.manageExternalStorage);
            await directory.create(recursive: true);
          }
          if (await directory.exists()) {
            try {
              return newPath;
            } catch (e) {
              rethrow;
            }
          }
        } else {
          return throw 'something went wrong';
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
        return directory.path;
      } else {
        directory = await getDownloadsDirectory();
        return directory!.path;
      }
    } catch (e) {
      rethrow;
    }
    return directory.path;
  }
}
