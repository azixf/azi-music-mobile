import 'package:flutter_displaymode/flutter_displaymode.dart';

Future<void> setOptimalDisplayMode() async {
  final List<DisplayMode> supportedDisplayMode =
      await FlutterDisplayMode.supported;
  final DisplayMode activeDisplayMode = await FlutterDisplayMode.active;

  final List<DisplayMode> sameResolution = supportedDisplayMode
      .where((DisplayMode element) =>
          element.width == activeDisplayMode.width &&
          element.height == activeDisplayMode.height)
      .toList()
    ..sort((DisplayMode a, DisplayMode b) =>
        b.refreshRate.compareTo(a.refreshRate));

  final DisplayMode mostOptimalMode = sameResolution.isNotEmpty ? sameResolution.first : activeDisplayMode;
  await FlutterDisplayMode.setPreferredMode(mostOptimalMode);

}
