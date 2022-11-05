import 'dart:async';
import 'dart:io';

import 'package:azi_music_mobile/screens/home/home.dart';
import 'package:azi_music_mobile/theme/app_theme.dart';
import 'package:azi_music_mobile/utils/hive_open_box.dart';
import 'package:azi_music_mobile/utils/init_service.dart';
import 'package:azi_music_mobile/utils/route_handler.dart';
import 'package:azi_music_mobile/utils/set_display_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/adapters.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Paint.enableDithering = true;

  if(Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await Hive.initFlutter('4U');
  } else {
    await Hive.initFlutter();
  }

  await openHiveBox('settings');
  await openHiveBox('downloads');
  await openHiveBox('Favorite Songs');
  await openHiveBox('cache', limit: true);

  if(Platform.isAndroid) {
    await setOptimalDisplayMode();
  }

  await initService();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({ Key? key }) : super(key: key);
  @override
  State<MyApp> createState() => _MyAppState();

  // static _MyAppState of(BuildContext context) =>
  //     context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  // TODO: sharing things
  // late StreamSubscription _intentDataStreamSubscription;
  final GlobalKey<NavigatorState> navigationKey = GlobalKey<NavigatorState>();


  @override
  void dispose() {
    // _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppTheme.themeMode == ThemeMode.dark ? Colors.black38 : Colors.white,
        statusBarIconBrightness: AppTheme.themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light,
        systemNavigationBarIconBrightness: AppTheme.themeMode == ThemeMode.dark ? Brightness.light : Brightness.dark,
      )
    );
    return MaterialApp(
      title: '4U',
      restorationScopeId: '4u',
      debugShowCheckedModeBanner: false,
      themeMode: AppTheme.themeMode,
      theme: AppTheme.lightTheme(context: context),
      darkTheme: AppTheme.darkTheme(context: context),
      routes: {
        '/': (_) => const HomePage(),
      },
      navigatorKey: navigationKey,
      onGenerateRoute: (RouteSettings settings) {
        return RouteHandler.handler(settings.name);
      },
    );
  }
}

