import 'package:azi_music_mobile/config/app_theme.dart';
import 'package:get_it/get_it.dart';

Future<void> initService() async {
  // TODO: register audio player service
  GetIt.I.registerSingleton<MyTheme>(MyTheme());
}
