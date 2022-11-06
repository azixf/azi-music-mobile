import 'dart:io';

import 'package:flutter/material.dart';

import '../../../components/gradient_container.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({
    Key? key,
    required this.appVersion,
  }) : super(key: key);

  final String? appVersion;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: GradientContainer(
        child: CustomScrollView(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          slivers: [
            DrawerAppBar(appVersion: appVersion),
            SliverList(
              delegate: SliverChildListDelegate([
                DrawerListItem(
                  title: '首页',
                  icon: Icons.home_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () {
                    Navigator.pop(context);
                  },
                  select: true,
                ),
                if (Platform.isAndroid)
                  DrawerListItem(
                      title: '我的音乐',
                      icon: Icons.add,
                      onTap: () {
                        Navigator.pop(context);
                      }),
                DrawerListItem(
                    title: '下载',
                    icon: Icons.download_done_rounded,
                    onTap: () {
                      Navigator.pop(context);
                    }),
                DrawerListItem(
                    title: '播放列表',
                    icon: Icons.playlist_play_rounded,
                    onTap: () {
                      Navigator.pop(context);
                    }),
                DrawerListItem(
                    title: '设置',
                    icon: Icons.settings_rounded,
                    onTap: () {
                      Navigator.pop(context);
                    }),
                DrawerListItem(
                    title: '关于',
                    icon: Icons.info_outline_rounded,
                    onTap: () {
                      Navigator.pop(context);
                    }),
              ]),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: const [
                  Spacer(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(5, 30, 5, 20),
                    child: Center(
                      child: Text(
                        '开发者：AZI',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.0),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class DrawerAppBar extends StatelessWidget {
  const DrawerAppBar({
    Key? key,
    required this.appVersion,
  }) : super(key: key);

  final String? appVersion;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      elevation: 0,
      stretch: true,
      expandedHeight: MediaQuery.of(context).size.height * 0.2,
      flexibleSpace: FlexibleSpaceBar(
        title: RichText(
          text: TextSpan(
              text: '4U',
              style: const TextStyle(
                  fontSize: 30.0, fontWeight: FontWeight.w500),
              children: [
                TextSpan(
                  text: appVersion == null ? '' : '\nv$appVersion',
                  style: const TextStyle(fontSize: 7.0),
                ),
              ]),
          textAlign: TextAlign.end,
        ),
        titlePadding: const EdgeInsets.only(bottom: 40),
        centerTitle: true,
        background: ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.1)
                ]).createShader(
                Rect.fromLTRB(0, 0, rect.width, rect.height));
          },
          blendMode: BlendMode.dstIn,
          child: Image(
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            image: AssetImage(
                Theme.of(context).brightness == Brightness.dark
                    ? 'assets/header-dark.jpg'
                    : 'assets/header.jpg'),
          ),
        ),
      ),
    );
  }
}

class DrawerListItem extends StatelessWidget {
  const DrawerListItem({
    Key? key,
    required this.title,
    this.color,
    this.select,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  final String title;
  final IconData icon;
  final Color? color;
  final bool? select;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Theme.of(context).iconTheme.color,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
      leading: Icon(
        icon,
        color: color ?? Theme.of(context).iconTheme.color,
      ),
      selected: select ?? false,
      onTap: onTap,
    );
  }
}