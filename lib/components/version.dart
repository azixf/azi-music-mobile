import 'package:azi_music_mobile/utils/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersion {
  // static Widget checkVersion(
  //     BuildContext context, bool checked, String appVersion) {
  //   if (!checked && Theme.of(context).platform == TargetPlatform.android) {
  //     final SupaBase db = SupaBase();
  //     bool checkUpdate =
  //         Hive.box('settings').get('checkUpdate', defaultValue: false);
  //     PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
  //       appVersion = packageInfo.version;
  //     });
  //   }
  // }
}
