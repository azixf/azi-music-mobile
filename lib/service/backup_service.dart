import 'dart:io';

import 'package:azi_music_mobile/components/snack_bar.dart';
import 'package:azi_music_mobile/service/picker_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> createBackup(
    BuildContext context, List items, Map<String, List> boxNameData,
    {String? path, String? fileName, bool showDialog = true}) async {
  if (!Platform.isWindows) {
    PermissionStatus permissionStatus = await Permission.storage.status;
    if (permissionStatus.isDenied) {
      await [
        Permission.storage,
        Permission.accessMediaLocation,
        Permission.mediaLibrary
      ].request();
    }
    permissionStatus = await Permission.storage.status;
    if (permissionStatus.isPermanentlyDenied) {
      await openAppSettings();
    }

    final String savePath =
        path ?? await Picker.selectFolder(context: context, message: '选择备份位置');

    if (savePath.trim() != '') {
      try {
        final saveDir = Directory(savePath);
        final List<File> files = [];
        final List boxNames = [];

        for (var item in items) {
          boxNames.addAll(boxNameData[item]!);
        }

        for (var boxName in boxNames) {
          await Hive.openBox(boxName.toString());
          try {
            await File(Hive.box(boxName.toString()).path!)
                .copy('$savePath/$boxName.hive');
          } catch (e) {
            await [Permission.manageExternalStorage].request();
            await File(Hive.box(boxName.toString()).path!)
                .copy('$savePath/$boxName.hive');
          }
          files.add(File('$savePath/$boxName.hive'));
        }

        final now = DateTime.now();
        final String time =
            '${now.year}${now.month}${now.day}_${now.hour}${now.minute}';
        final zipFile = File('$savePath/${fileName ?? "4U_Backup_$time"}.zip');

        await ZipFile.createFromFiles(
            sourceDir: saveDir, files: files, zipFile: zipFile);

        for (File file in files) {
          file.delete();
        }

        if (showDialog) {
          // ignore: use_build_context_synchronously
          ShowSnackBar().showSnackBar(context, '备份成功');
        }
      } catch (e) {
        // ignore: use_build_context_synchronously
        ShowSnackBar().showSnackBar(context, '创建备份失败\nErroor: $e');
      }
    } else {
      // ignore: use_build_context_synchronously
      ShowSnackBar().showSnackBar(context, '尚未选择文件夹');
    }
  }
}

Future<void> restore(BuildContext context) async {
  final String savePath =
      await Picker.selectFile(context: context, message: '选择备份文件');
  final File zipFile = File(savePath);
  final Directory tempDir = await getTemporaryDirectory();
  final Directory destinationDir = Directory('${tempDir.path}/restore');

  try {
    await ZipFile.extractToDirectory(
        zipFile: zipFile, destinationDir: destinationDir);
    final List<FileSystemEntity> files = await destinationDir.list().toList();

    for (FileSystemEntity entity in files) {
      final String backupPath = entity.path;
      final String boxName = backupPath.split('/').last.replaceAll('.hive', '');
      final Box box = await Hive.openBox(boxName);
      final String boxPath = box.path!;
      await box.close();

      try {
        await File(backupPath).copy(boxPath);
      } catch (e) {
        await Hive.openBox(boxName);
      }

      destinationDir.delete(recursive: true);
      // ignore: use_build_context_synchronously
      ShowSnackBar().showSnackBar(context, '备份导入成功');
    }
  } catch (e) {
    // ignore: use_build_context_synchronously
    ShowSnackBar().showSnackBar(context, '备份导入失败\nError: $e');
  }
}
