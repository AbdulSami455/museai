// This page builds the UI for song browsing and playback.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:museai/common/helpers/is_dark_mode.dart';
import 'package:museai/common/widgets/appbar/app_bar_widget.dart';
import 'package:museai/core/configs/themes/app_colors.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/entities/playable.dart';
import 'package:museai/domain/entities/song/song_entity.dart';
import 'package:museai/presentation/song_player/bloc/song_player_cubit.dart';
import 'package:museai/presentation/song_player/bloc/song_player_state.dart';
import 'package:museai/presentation/studio/pages/studio_page.dart';
import 'package:museai/service_locator.dart';
import 'package:path_provider/path_provider.dart';

class SongPlayerPage extends StatefulWidget {
  final List<SongEntity> songsList;
  final Playable song;

  const SongPlayerPage({
    super.key,
    required this.song,
    required this.songsList,
  });

  @override
  State<SongPlayerPage> createState() => _SongPlayerPageState();
}

class _SongPlayerPageState extends State<SongPlayerPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    sl<SongPlayerCubit>().loadSong(widget.song);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _syncRotation(bool isPlaying) {
    if (isPlaying) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final generation = widget.song is GenerationEntity
        ? widget.song as GenerationEntity
        : null;

    return BlocProvider.value(
      value: sl<SongPlayerCubit>(),
      child: Scaffold(
        appBar: const AppBarWidget(
          title: Text(
            'Now Playing',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.grey[900],
                    image: widget.song.coverUrl != null
                        ? DecorationImage(
                            image: NetworkImage(widget.song.coverUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    gradient: widget.song.coverUrl == null
                        ? const LinearGradient(
                            colors: [Color(0xFF172554), Color(0xFF0F766E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.song.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.song.artist ?? 'MuseAI Track',
                            style: const TextStyle(fontSize: 15),
                          ),
                          if (generation?.parentId != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Remix of ${generation!.parentId}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.favorite_border_rounded,
                      color: context.isDarkMode
                          ? AppColors.lightBackgroundColor
                              .withValues(alpha: 0.5)
                          : AppColors.darkBackgroundColor
                              .withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
              _actionBar(context, generation),
              const SizedBox(height: 10),
              _songPlayerWidget(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBar(BuildContext context, GenerationEntity? generation) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        if (generation != null)
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudioPage(remixSource: generation),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Remix'),
          ),
        OutlinedButton.icon(
          onPressed: _downloading ? null : () => _downloadTrack(context),
          icon: Icon(_downloading
              ? Icons.downloading_rounded
              : Icons.download_rounded),
          label: Text(_downloading ? 'Downloading...' : 'Download'),
        ),
        OutlinedButton.icon(
          onPressed: () => _shareTrack(context, generation),
          icon: const Icon(Icons.share_outlined),
          label: const Text('Share'),
        ),
      ],
    );
  }

  Widget _songPlayerWidget(BuildContext context) {
    return BlocBuilder<SongPlayerCubit, SongPlayerState>(
      builder: (context, songState) {
        if (songState is SongPlayerLoading) {
          return Container(
            alignment: Alignment.center,
            child: LoadingAnimationWidget.staggeredDotsWave(
              color: AppColors.primaryColor,
              size: 50,
            ),
          );
        }
        if (songState is SongPlayerFailure) {
          return const SizedBox.shrink();
        }
        if (songState is SongPlayerLoaded) {
          final isPlaying = sl<SongPlayerCubit>().audioPlayer.playing;
          _syncRotation(isPlaying);

          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Builder(
                builder: (_) {
                  final position =
                      sl<SongPlayerCubit>().songPosition.inSeconds.toDouble();
                  final duration =
                      sl<SongPlayerCubit>().songDuration.inSeconds.toDouble();
                  final safeMax = duration <= 0 ? 1.0 : duration;
                  final safeValue = position > safeMax ? safeMax : position;
                  return Slider(
                    activeColor: AppColors.primaryColor,
                    value: safeValue,
                    min: 0.0,
                    max: safeMax,
                    onChanged: (value) {
                      sl<SongPlayerCubit>()
                          .jumpTo(Duration(seconds: value.toInt()));
                    },
                  );
                },
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(sl<SongPlayerCubit>().songPosition)),
                  Text(_formatDuration(sl<SongPlayerCubit>().songDuration)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.song is SongEntity && widget.songsList.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SongPlayerPage(
                              song: _prevSong(),
                              songsList: widget.songsList,
                            ),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.skip_previous_rounded,
                        size: 30,
                        color: AppColors.grey,
                      ),
                    )
                  else
                    const SizedBox(width: 30),
                  const SizedBox(width: 15),
                  GestureDetector(
                    onTap: () {
                      sl<SongPlayerCubit>().playOrPauseSong();
                      setState(() {});
                    },
                    child: RotationTransition(
                      turns: _rotationController,
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryColor,
                        ),
                        child: Icon(
                          isPlaying
                              ? Icons.pause_sharp
                              : Icons.play_arrow_rounded,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  if (widget.song is SongEntity && widget.songsList.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SongPlayerPage(
                              song: _nextSong(),
                              songsList: widget.songsList,
                            ),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.skip_next_rounded,
                        size: 30,
                        color: AppColors.grey,
                      ),
                    )
                  else
                    const SizedBox(width: 30),
                ],
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  int _currentIndex() {
    final song = widget.song;
    if (song is SongEntity) {
      final i = widget.songsList.indexOf(song);
      return i < 0 ? 0 : i;
    }
    return 0;
  }

  SongEntity _nextSong() {
    final index = _currentIndex();
    return widget.songsList[(index + 1) % widget.songsList.length];
  }

  SongEntity _prevSong() {
    final index = _currentIndex();
    return widget.songsList[
        (index - 1 + widget.songsList.length) % widget.songsList.length];
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _downloadTrack(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _downloading = true);
    try {
      final response = await http.get(Uri.parse(widget.song.audioUrl));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Download failed.');
      }
      final directory = await getApplicationDocumentsDirectory();
      final safeTitle =
          widget.song.title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
      final file = File('${directory.path}/$safeTitle.mp3');
      await file.writeAsBytes(response.bodyBytes);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Saved to ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _shareTrack(
      BuildContext context, GenerationEntity? generation) async {
    final messenger = ScaffoldMessenger.of(context);
    final shareValue = generation?.shareSlug ?? widget.song.audioUrl;
    await Clipboard.setData(ClipboardData(text: shareValue));
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          generation?.shareSlug != null
              ? 'Share slug copied: ${generation!.shareSlug}'
              : 'Track URL copied to clipboard.',
        ),
      ),
    );
  }
}
