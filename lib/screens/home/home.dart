import 'dart:math';

import 'package:azi_music_mobile/components/custom_physics.dart';
import 'package:azi_music_mobile/components/gradient_container.dart';
import 'package:azi_music_mobile/components/snack_bar.dart';
import 'package:azi_music_mobile/components/text_input_dialog.dart';
import 'package:azi_music_mobile/service/backup_service.dart';
import 'package:azi_music_mobile/utils/common.dart';
import 'package:azi_music_mobile/utils/ext_storage.dart';
import 'package:azi_music_mobile/utils/supabase_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import 'components/drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? appVersion;
  bool checked = false;
  bool checkUpdate =
      Hive.box('settings').get('checkUpdate', defaultValue: true);
  bool autoBackup = Hive.box('settings').get('autoBackup', defaultValue: true);

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  // 检查更新、自动备份
  Widget checkVersion() {
    if (!checked && Theme.of(context).platform == TargetPlatform.android) {
      checked = true;
      final SupaBase supaBase = SupaBase();

      PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
        appVersion = packageInfo.version;

        if (checkUpdate) {
          supaBase.getUpdate().then((Map map) async {
            if (compareVersion(map['LatestVersion'], appVersion!)) {
              List? abis = Hive.box('settings').get('supportedAbis') as List?;
              if (abis == null) {
                final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
                final AndroidDeviceInfo androidDeviceInfo =
                    await deviceInfo.androidInfo;
                abis = androidDeviceInfo.supportedAbis;
                await Hive.box('settings').put('supportedAbis', abis);
              }
              if (mounted) {
                ShowSnackBar().showSnackBar(context, '当前有可用更新!',
                    duration: const Duration(seconds: 15),
                    action: SnackBarAction(
                        textColor: Theme.of(context).colorScheme.secondary,
                        label: '立即更新',
                        onPressed: () {
                          Navigator.pop(context);
                          if (abis!.contains('arm64-v8a')) {
                            launchUrl(Uri.parse(map['arm64-v8a']),
                                mode: LaunchMode.externalApplication);
                          } else {
                            if (abis.contains('armeabi-v7a')) {
                              launchUrl(Uri.parse(map['arneabi-v7a']),
                                  mode: LaunchMode.externalApplication);
                            } else {
                              launchUrl(Uri.parse(map['universal']),
                                  mode: LaunchMode.externalApplication);
                            }
                          }
                        }));
              }
            }
          });
        }

        if (autoBackup) {
          final List<String> checked = ['设置', '下载', '播放列表'];

          final List playListNames = Hive.box('settings')
              .get('playListNames', defaultValue: ['Favorite Songs']);

          final Map<String, List> boxNames = {
            '设置': ['settings'],
            '缓存': ['cache'],
            '下载': ['downloads'],
            '播放列表': playListNames
          };

          final String backupPath =
              Hive.box('settings').get('backupPath', defaultValue: '');

          if (backupPath == '') {
            ExtStroageProvider.getExtrStorge(dirname: '4U/Backups')
                .then((value) {
              Hive.box('settings').put('backupPath', value);
              createBackup(context, checked, boxNames,
                  path: value, fileName: '4U_AutoBackup', showDialog: false);
            });
          } else {
            createBackup(context, checked, boxNames,
                path: backupPath, fileName: '4U_AutoBackup', showDialog: false);
          }
        }
      });
      return const SizedBox();
    } else {
      return const SizedBox();
    }
  }

  DateTime? backButtonPressTime;
  // 检测退出app
  Future<bool> handleWillPop(BuildContext context) async {
    final now = DateTime.now();
    final backButtonNotBeenPressedOrSnackBarhasBeenClosed =
        backButtonPressTime == null ||
            now.difference(backButtonPressTime!) > const Duration(seconds: 3);
    if (backButtonNotBeenPressedOrSnackBarhasBeenClosed) {
      backButtonPressTime = now;
      ShowSnackBar().showSnackBar(context, '再次点击返回按钮退出应用',
          duration: const Duration(seconds: 2), noAction: true);
      return false;
    }
    return true;
  }

  final ValueNotifier<int> _selectedIndex = ValueNotifier<int>(0);
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();

  String name = Hive.box('settings').get('name', defaultValue: 'Guest');

  void _onItemTapped(int index) {
    _selectedIndex.value = index;
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
        child: Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      drawer: HomeDrawer(appVersion: appVersion),
      body: WillPopScope(
        onWillPop: () => handleWillPop(context),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        physics: const CustomPhysics(),
                        onPageChanged: (index) {
                          _selectedIndex.value = index;
                        },
                        controller: _pageController,
                        children: [
                          Stack(
                            children: [
                              checkVersion(),
                              NestedScrollView(
                                physics: const BouncingScrollPhysics(),
                                controller: _scrollController,
                                headerSliverBuilder: (BuildContext context,
                                    bool innerBoxScrolled) {
                                  return [
                                    SliverAppBar(
                                      expandedHeight: 135,
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      toolbarHeight: 65,
                                      automaticallyImplyLeading: false,
                                      flexibleSpace: LayoutBuilder(
                                        builder: (BuildContext context,
                                            BoxConstraints constraints) {
                                          return FlexibleSpaceBar(
                                            background: GestureDetector(
                                              onTap: () async {
                                                await showTextInputDialog(
                                                  context: context,
                                                  title: 'Name',
                                                  initialText: name,
                                                  keyboardType:
                                                      TextInputType.name,
                                                  onSubmitted: (value) {
                                                    Hive.box('settings').put(
                                                        'name', value.trim());
                                                    name = value.trim();
                                                    Navigator.pop(context);
                                                  },
                                                );
                                                setState(() {});
                                              },
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const SizedBox(height: 60),
                                                  Row(
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                left: 15.0),
                                                        child: Text(
                                                          '欢迎您',
                                                          style: TextStyle(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .secondary,
                                                              fontSize: 30,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 15.0),
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .end,
                                                      children: [
                                                        ValueListenableBuilder(
                                                          valueListenable:
                                                              Hive.box(
                                                                      'settings')
                                                                  .listenable(),
                                                          builder: (BuildContext
                                                                  context,
                                                              Box box,
                                                              Widget? child) {
                                                            return Text(
                                                              (box.get('name') ==
                                                                          null ||
                                                                      box.get('name') ==
                                                                          ''
                                                                  ? 'Guest'
                                                                  : (box.get('name')
                                                                          as String)
                                                                      .split(
                                                                          ' ')[0]
                                                                      .toString()),
                                                              style: const TextStyle(
                                                                  letterSpacing:
                                                                      2,
                                                                  fontSize: 20,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500),
                                                            );
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    SliverAppBar(
                                      automaticallyImplyLeading: false,
                                      pinned: true,
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      stretch: true,
                                      toolbarHeight: 65,
                                      title: Align(
                                        alignment: Alignment.centerRight,
                                        child: AnimatedBuilder(
                                          animation: _scrollController,
                                          builder: (BuildContext context,
                                              Widget? child) {
                                            return GestureDetector(
                                              child: AnimatedContainer(
                                                width: (!_scrollController
                                                            .hasClients ||
                                                        _scrollController
                                                                .positions
                                                                .length >
                                                            1)
                                                    ? MediaQuery.of(context)
                                                        .size
                                                        .width
                                                    : max(
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width -
                                                            _scrollController
                                                                .offset
                                                                .roundToDouble(),
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width -
                                                            75),
                                                height: 52,
                                                duration: const Duration(
                                                    milliseconds: 150),
                                                padding:
                                                    const EdgeInsets.all(2.0),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10.0),
                                                  color: Theme.of(context)
                                                      .cardColor,
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: Colors.black26,
                                                      blurRadius: 5.0,
                                                      offset: Offset(1.5, 1.5),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  children: [
                                                    const SizedBox(
                                                      width: 10.0,
                                                    ),
                                                    Icon(
                                                      CupertinoIcons.search,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .secondary,
                                                    ),
                                                    const SizedBox(
                                                      width: 10.0,
                                                    ),
                                                    Text(
                                                      '请输入歌曲/歌手/专辑/MV进行搜索',
                                                      style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .secondary,
                                                          fontSize: 16.0,
                                                          fontWeight: FontWeight
                                                              .normal),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              onTap: () {
                                                // TODO: add search tap handler
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ];
                                },
                                body: Container(),
                              ),
                              Builder(
                                builder: (BuildContext context) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        left: 4.0, top: 8.0),
                                    child: Transform.rotate(
                                      angle: 22 / 7 * 2,
                                      child: IconButton(
                                        onPressed: () {
                                          Scaffold.of(context).openDrawer();
                                        },
                                        icon: const Icon(
                                            Icons.horizontal_split_rounded),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // TODO: mini player
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: _selectedIndex,
          builder: (BuildContext context, int indexValue, Widget? child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              height: 60,
              child: SalomonBottomBar(
                currentIndex: indexValue,
                onTap: _onItemTapped,
                items: [
                  SalomonBottomBarItem(
                    icon: Icon(Icons.home_rounded),
                    title: Text('首页'),
                    selectedColor: Theme.of(context).colorScheme.secondary
                  ),
                  SalomonBottomBarItem(
                    icon: Icon(Icons.home_rounded),
                    title: Text('首页'),
                    selectedColor: Theme.of(context).colorScheme.secondary
                  ),
                  SalomonBottomBarItem(
                    icon: Icon(Icons.home_rounded),
                    title: Text('首页'),
                    selectedColor: Theme.of(context).colorScheme.secondary
                  ),
                  SalomonBottomBarItem(
                    icon: Icon(Icons.home_rounded),
                    title: Text('首页'),
                    selectedColor: Theme.of(context).colorScheme.secondary
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ));
  }
}
