import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:museai/core/configs/assets/app_vectors.dart';
import 'package:museai/presentation/home/widgets/home_artist_widget.dart';
import 'package:museai/presentation/home/widgets/home_playlist_widget.dart';
import 'package:museai/presentation/home/widgets/home_tabs_widget.dart';
import 'package:museai/presentation/library/pages/library_page.dart';
import 'package:museai/presentation/profile/pages/profile_settings_page.dart';
import 'package:museai/presentation/studio/pages/studio_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const StudioPage(compactMode: true),
      const LibraryPage(),
      const _DiscoverPage(),
    ];
    final titles = ['Create', 'Library', 'Discover'];

    return Scaffold(
      appBar: AppBar(
        title: _currentIndex == 2
            ? SvgPicture.asset(AppVectors.logo, height: 38, width: 38)
            : Text(
                titles[_currentIndex],
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileSettingsPage()),
              );
            },
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_mosaic_outlined),
            selectedIcon: Icon(Icons.auto_awesome_mosaic_rounded),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music_rounded),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Discover',
          ),
        ],
      ),
    );
  }
}

class _DiscoverPage extends StatelessWidget {
  const _DiscoverPage();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        child: Column(
          children: [
            HomeArtistWidget(),
            HomeTabsWidget(),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  Text(
                    'Discovery Mix',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
            ),
            HomePlaylistWidget(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
