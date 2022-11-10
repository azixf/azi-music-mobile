import 'package:flutter/material.dart';

class HorizontalAlbumList extends StatefulWidget {
  const HorizontalAlbumList(
      {super.key, required this.songsList, required this.onTap});

  final List songsList;
  final Function(int) onTap;

  @override
  State<HorizontalAlbumList> createState() => _HorizontalAlbumListState();
}

class _HorizontalAlbumListState extends State<HorizontalAlbumList> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
