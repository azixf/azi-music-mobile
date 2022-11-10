import 'package:azi_music_mobile/screens/home/components/horizontal_album_list.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

bool fetched = false;
List likedRadio = Hive.box('settings').get('likedRadio', defaultValue: []);
Map data = Hive.box('cache').get('homePage', defaultValue: {});
List lists = ['recent', 'playlist', ...?data['collections']];

class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody>
    with AutomaticKeepAliveClientMixin<HomeBody> {
  List recentList = Hive.box('cache').get('recentSongs', defaultValue: []);
  Map likedArtists = Hive.box('settings').get('likedArtists', defaultValue: {});
  List blacklistedHomeSections =
      Hive.box('settings').get('blacklistedHomeSections', defaultValue: []);
  List playlistNames =
      Hive.box('settings').get('playlistNames')?.toList() ?? ['Favorite Songs'];
  Map playlistDetails =
      Hive.box('settings').get('playlistDetails', defaultValue: {});

  int recentIndex = 0;
  int playlistIndex = 1;

  Future<void> getHomeData() async {
    // TODO
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!fetched) {
      getHomeData();
      fetched = true;
    }

    if (recentList.length < playlistNames.length) {
      recentIndex = 0;
      playlistIndex = 1;
    } else {
      recentIndex = 1;
      playlistIndex = 0;
    }

    return (data.isEmpty && recentList.isEmpty)
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
            itemCount: data.isEmpty ? 2 : lists.length,
            itemBuilder: (BuildContext context, int idx) {
              if (idx == recentIndex) {
                return (recentList.isEmpty ||
                        !(Hive.box('settings')
                            .get('showRecent', defaultValue: true))
                    ? const SizedBox()
                    : Column(
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(15, 10, 0, 5),
                                child: Text(
                                  '最近收听',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold
                                      ),
                                ),
                              ),
                            ],
                          ),
                          HorizontalAlbumList(),
                        ],
                      ));
              }
            },
          );
  }
}
