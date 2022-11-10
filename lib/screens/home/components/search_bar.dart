import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget homeSearchBar(ScrollController scrollController) {
  return SliverAppBar(
    automaticallyImplyLeading: false,
    pinned: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    stretch: true,
    toolbarHeight: 65,
    title: Align(
      alignment: Alignment.centerRight,
      child: AnimatedBuilder(
        animation: scrollController,
        builder: (BuildContext context, Widget? child) {
          return GestureDetector(
            child: AnimatedContainer(
              width: (!scrollController.hasClients ||
                      scrollController.positions.length > 1)
                  ? MediaQuery.of(context).size.width
                  : max(
                      MediaQuery.of(context).size.width -
                          scrollController.offset.roundToDouble(),
                      MediaQuery.of(context).size.width - 75),
              height: 52,
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: Theme.of(context).cardColor,
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
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(
                    width: 10.0,
                  ),
                  Text(
                    '请输入歌曲/歌手/专辑/MV',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 16.0,
                        fontWeight: FontWeight.normal),
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
  );
}