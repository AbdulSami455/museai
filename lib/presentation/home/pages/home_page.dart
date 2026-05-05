import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:museai/presentation/auth/pages/auth_page.dart';
import 'package:museai/presentation/home/widgets/home_tabs_widget.dart';
import 'package:museai/presentation/studio/pages/studio_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../common/widgets/appbar/app_bar_widget.dart';
import '../../../core/configs/assets/app_vectors.dart';
import '../widgets/home_artist_widget.dart';
import '../widgets/home_playlist_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBarWidget(
        showBackButton: false,
        title: SvgPicture.asset(
          AppVectors.logo,
          height: 40,
          width: 40,
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthPage()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudioPage()),
        ),
        backgroundColor: Colors.deepPurpleAccent,
        icon: const Icon(Icons.music_note, color: Colors.white),
        label: const Text('Create', style: TextStyle(color: Colors.white)),
      ),
      body:const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              HomeArtistWidget(
              ),
              HomeTabsWidget(),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Playlist',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20
                      ),
                    ),
                  ],
                ),
              ),
              HomePlaylistWidget()
            ],
          ),
        ),
      ),
    );
  }
}
