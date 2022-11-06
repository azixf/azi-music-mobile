import 'package:audio_service/audio_service.dart';
import 'package:azi_music_mobile/components/audio_player.dart';
import 'package:azi_music_mobile/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../service/audio_service.dart';

Future<void> initService() async {
  final AudioPlayerHandler audioPlayerHandler = await AudioService.init(
      builder: () => AudioPlayerHandlerImpl(),
      config: AudioServiceConfig(
        androidNotificationChannelId:
            'com.example.azi_music_mobile.channel.audio',
        androidNotificationChannelName: '4U',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'drawable/ic_stat_music_note',
        androidShowNotificationBadge: true,
        notificationColor: Colors.grey[900],
      ));

  GetIt.I.registerSingleton<AudioPlayerHandler>(audioPlayerHandler);
  GetIt.I.registerSingleton<MyTheme>(MyTheme());
}
