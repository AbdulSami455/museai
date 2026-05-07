// This page builds the UI for the library section.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/entities/playlist/playlist_entity.dart';
import 'package:museai/presentation/library/bloc/library_cubit.dart';
import 'package:museai/presentation/library/bloc/library_state.dart';
import 'package:museai/presentation/library/pages/playlist_detail_page.dart';
import 'package:museai/presentation/library/widgets/library_track_row.dart';
import 'package:museai/presentation/song_player/pages/song_player_page.dart';
import 'package:museai/service_locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      sl<LibraryCubit>().load(uid);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<LibraryCubit>(),
      child: BlocBuilder<LibraryCubit, LibraryState>(
        builder: (context, state) {
          if (state is LibraryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is LibraryError) {
            return _CenteredMessage(
              title: 'Library unavailable',
              body: state.message,
            );
          }

          if (state is! LibraryLoaded) {
            return const SizedBox.shrink();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Library',
                            style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Browse generations, organize playlists, and prep tracks to share.',
                            style:
                                TextStyle(fontSize: 13, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Tracks'),
                    Tab(text: 'Playlists'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _TracksTab(
                      tracks: state.tracks,
                      playlists: state.playlists,
                    ),
                    _PlaylistsTab(
                      playlists: state.playlists,
                      tracks: state.tracks,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TracksTab extends StatelessWidget {
  final List<GenerationEntity> tracks;
  final List<PlaylistEntity> playlists;

  const _TracksTab({required this.tracks, required this.playlists});

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return const _CenteredMessage(
        title: 'No tracks yet',
        body: 'Generate your first track in Create and it will appear here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: tracks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final track = tracks[index];
        return LibraryTrackRow(
          track: track,
          subtitle: '${track.genre} • ${track.mood} • ${track.bpm} BPM',
          onTap: () {
            if (track.audioUrlNullable == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('This track is still processing.')),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SongPlayerPage(song: track, songsList: const []),
              ),
            );
          },
          onRename: () => _showRenameDialog(context, track),
          onAddToPlaylist: () =>
              _showAddToPlaylistSheet(context, track, playlists),
          onDelete: () => _deleteTrack(context, track),
        );
      },
    );
  }

  Future<void> _showRenameDialog(
      BuildContext context, GenerationEntity track) async {
    final controller = TextEditingController(text: track.prompt);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Track'),
        content: TextField(
          controller: controller,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'New track title/prompt'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty || !context.mounted) return;
    final failure =
        await context.read<LibraryCubit>().renameTrack(track.id, result);
    if (context.mounted && failure != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _showAddToPlaylistSheet(
    BuildContext context,
    GenerationEntity track,
    List<PlaylistEntity> playlists,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0B1120),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add to playlist',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child:
                      Text('Create a playlist first from the Playlists tab.'),
                ),
              ...playlists.map(
                (playlist) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(playlist.name),
                  subtitle: Text('${playlist.trackIds.length} tracks'),
                  trailing: playlist.trackIds.contains(track.id)
                      ? const Icon(Icons.check_circle, color: Color(0xFF4ADE80))
                      : const Icon(Icons.add_circle_outline),
                  onTap: () async {
                    final failure = await context
                        .read<LibraryCubit>()
                        .addTrackToPlaylist(playlist.id, track.id);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            failure?.message ?? 'Added to ${playlist.name}.',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteTrack(
      BuildContext context, GenerationEntity track) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Track'),
            content: const Text(
              'This removes the track from your library and any playlists that include it.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    final failure = await context.read<LibraryCubit>().deleteTrack(track.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure?.message ?? 'Track deleted.')),
      );
    }
  }
}

class _PlaylistsTab extends StatelessWidget {
  final List<PlaylistEntity> playlists;
  final List<GenerationEntity> tracks;

  const _PlaylistsTab({required this.playlists, required this.tracks});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        FilledButton.icon(
          onPressed: () => _showCreatePlaylistDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Create Playlist'),
        ),
        const SizedBox(height: 16),
        if (playlists.isEmpty)
          const _CenteredMessage(
            title: 'No playlists yet',
            body: 'Create your first playlist to organize generated tracks.',
          )
        else
          ...playlists.map(
            (playlist) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  final playlistTracks = <GenerationEntity>[];
                  for (final id in playlist.trackIds) {
                    for (final track in tracks) {
                      if (track.id == id) {
                        playlistTracks.add(track);
                        break;
                      }
                    }
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<LibraryCubit>(),
                        child: PlaylistDetailPage(
                          playlist: playlist,
                          tracks: playlistTracks,
                        ),
                      ),
                    ),
                  );
                },
                child: Ink(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF172554), Color(0xFF0F766E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playlist.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              playlist.description ?? 'No description',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${playlist.trackIds.length} tracks • ${playlist.visibility.name}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.68),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        color: const Color(0xFF111827),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _showEditPlaylistDialog(context, playlist);
                              break;
                            case 'copy':
                              Clipboard.setData(
                                  ClipboardData(text: playlist.name));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Playlist name copied.')),
                              );
                              break;
                            case 'delete':
                              _deletePlaylist(context, playlist);
                              break;
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(
                              value: 'copy', child: Text('Copy name')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final created = await showDialog<(String, String?)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Playlist name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              maxLines: 2,
              decoration:
                  const InputDecoration(hintText: 'Description (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              (nameController.text.trim(), descriptionController.text.trim()),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (created == null || created.$1.isEmpty || !context.mounted) return;
    final uid = Supabase.instance.client.auth.currentUser?.id ?? 'mock-user';
    final failure = await context.read<LibraryCubit>().createPlaylist(
          uid: uid,
          name: created.$1,
          description: created.$2?.isEmpty == true ? null : created.$2,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure?.message ?? 'Playlist created.')),
      );
    }
  }

  Future<void> _showEditPlaylistDialog(
      BuildContext context, PlaylistEntity playlist) async {
    final nameController = TextEditingController(text: playlist.name);
    final descriptionController =
        TextEditingController(text: playlist.description);
    final edited = await showDialog<(String, String?)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Playlist name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              (nameController.text.trim(), descriptionController.text.trim()),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (edited == null || edited.$1.isEmpty || !context.mounted) return;
    final failure = await context.read<LibraryCubit>().renamePlaylist(
          playlist.id,
          edited.$1,
          edited.$2?.isEmpty == true ? null : edited.$2,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure?.message ?? 'Playlist updated.')),
      );
    }
  }

  Future<void> _deletePlaylist(
      BuildContext context, PlaylistEntity playlist) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Playlist'),
            content: Text(
                'Delete "${playlist.name}"? Tracks will remain in your library.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    final failure =
        await context.read<LibraryCubit>().deletePlaylist(playlist.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure?.message ?? 'Playlist deleted.')),
      );
    }
  }
}

class _CenteredMessage extends StatelessWidget {
  final String title;
  final String body;

  const _CenteredMessage({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_music_rounded, size: 54),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
            ),
          ],
        ),
      ),
    );
  }
}
