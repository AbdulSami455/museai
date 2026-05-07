// This widget renders a reusable piece of the home screen.

import 'package:flutter/material.dart';
import 'package:museai/common/helpers/is_dark_mode.dart';
import 'package:museai/core/configs/themes/app_colors.dart';
import 'package:museai/data/source/home/placeholder_podcasts.dart';
import 'package:museai/presentation/home/widgets/home_artists_tab_widget.dart';
import 'package:museai/presentation/home/widgets/news_songs_widget.dart';

class HomeTabsWidget extends StatefulWidget {
  const HomeTabsWidget({super.key});

  @override
  State<HomeTabsWidget> createState() => _HomeTabsWidgetState();
}

class _HomeTabsWidgetState extends State<HomeTabsWidget>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    tabController = TabController(length: 4, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primaryColor,
          controller: tabController,
          labelColor: context.isDarkMode ? Colors.white : Colors.black,
          dividerHeight: 0,
          isScrollable: true,
          padding: const EdgeInsets.symmetric(vertical: 20),
          tabs: const [
            Text(
              'News',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'Videos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'Artist',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'Podcast',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        SizedBox(
          height: 200,
          child: TabBarView(
            controller: tabController,
            children: [
              const NewsSongsWidget(),
              const NewsSongsWidget(),
              const HomeArtistsTabWidget(),
              NewsSongsWidget(songs: PlaceholderPodcasts.items),
            ],
          ),
        ),
      ],
    );
  }
}
