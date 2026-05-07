// This page builds the UI for the library section.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:museai/common/widgets/appbar/app_bar_widget.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/entities/playlist/playlist_entity.dart';
import 'package:museai/presentation/library/bloc/library_cubit.dart';
import 'package:museai/presentation/library/widgets/library_track_row.dart';
import 'package:museai/presentation/song_player/pages/song_player_page.dart';

class PlaylistDetailPage extends StatelessWidget {
  final PlaylistEntity playlist;
  final List<GenerationEntity> tracks;

  const PlaylistDetailPage({
    super.key,
    required this.playlist,
    required this.tracks,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: Text(
          playlist.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              playlist.description ?? 'No description yet.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
            ),
            const SizedBox(height: 10),
            Text(
              '${tracks.length} tracks • ${playlist.visibility.name}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: tracks.isEmpty
                  ? _EmptyPlaylistState(name: playlist.name)
                  : ListView.separated(
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        return LibraryTrackRow(
                          track: track,
                          subtitle:
                              '${track.genre} • ${track.mood} • ${track.bpm} BPM',
                          onTap: () {
                            if (track.audioUrlNullable == null) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SongPlayerPage(
                                  song: track,
                                  songsList: const [],
                                ),
                              ),
                            );
                          },
                          onRename: () {},
                          onAddToPlaylist: () async {
                            final failure = await context
                                .read<LibraryCubit>()
                                .removeTrackFromPlaylist(playlist.id, track.id);
                            if (context.mounted && failure != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(failure.message)),
                              );
                            }
                            if (context.mounted && failure == null) {
                              Navigator.pop(context);
                            }
                          },
                          onDelete: () async {
                            final failure = await context
                                .read<LibraryCubit>()
                                .removeTrackFromPlaylist(playlist.id, track.id);
                            if (context.mounted && failure != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(failure.message)),
                              );
                            }
                            if (context.mounted && failure == null) {
                              Navigator.pop(context);
                            }
                          },
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: tracks.length,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPlaylistState extends StatelessWidget {
  final String name;

  const _EmptyPlaylistState({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.queue_music_rounded, size: 54),
          const SizedBox(height: 14),
          Text(
            '$name is empty',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Add tracks from your library to start shaping this set.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.68)),
          ),
        ],
      ),
    );
  }
}
