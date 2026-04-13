import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:museai/common/helpers/is_dark_mode.dart';
import 'package:museai/common/widgets/appbar/app_bar_widget.dart';
import 'package:museai/core/configs/themes/app_colors.dart';
import 'package:museai/domain/entities/playable.dart';
import 'package:museai/domain/entities/song/song_entity.dart';
import 'package:museai/presentation/song_player/bloc/song_player_cubit.dart';
import 'package:museai/presentation/song_player/bloc/song_player_state.dart';
import 'package:museai/service_locator.dart';

class SongPlayerPage extends StatefulWidget {
  final List<SongEntity> songsList;
  final Playable song;
  const SongPlayerPage({super.key, required this.song, required this.songsList});

  @override
  State<SongPlayerPage> createState() => _SongPlayerPageState();
}

class _SongPlayerPageState extends State<SongPlayerPage>
    with SingleTickerProviderStateMixin {
  // Animation 4: RotationTransition — play button rotates continuously while playing.
  late final AnimationController _rotationController;

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
                            // Animation 5: Hero tag applied in NewsSongsWidget;
                            // the container here is the destination.
                            image: NetworkImage(widget.song.coverUrl!),
                            fit: BoxFit.cover,
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
                    Column(
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
                          widget.song.artist ?? '',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.favorite_border_rounded,
                      color: context.isDarkMode
                          ? AppColors.lightBackgroundColor.withValues(alpha: 0.5)
                          : AppColors.darkBackgroundColor.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
              _songPlayerWidget(context),
            ],
          ),
        ),
      ),
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
              Slider(
                activeColor: AppColors.primaryColor,
                value: sl<SongPlayerCubit>().songPosition.inSeconds.toDouble(),
                min: 0.0,
                max: sl<SongPlayerCubit>().songDuration.inSeconds.toDouble(),
                onChanged: (value) {
                  sl<SongPlayerCubit>().jumpTo(Duration(seconds: value.toInt()));
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
                      child: const Icon(Icons.skip_previous_rounded,
                          size: 30, color: AppColors.grey),
                    )
                  else
                    const SizedBox(width: 30),
                  const SizedBox(width: 15),
                  GestureDetector(
                    onTap: () {
                      sl<SongPlayerCubit>().playOrPauseSong();
                      // Trigger rebuild so rotation syncs immediately.
                      setState(() {});
                    },
                    child: RotationTransition(
                      // Animation 4: play button icon rotates while song plays.
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
                      child: const Icon(Icons.skip_next_rounded,
                          size: 30, color: AppColors.grey),
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
    assert(widget.song is SongEntity && widget.songsList.isNotEmpty,
        '_nextSong() must only be called when song is SongEntity and songsList is non-empty');
    final index = _currentIndex();
    return widget.songsList[(index + 1) % widget.songsList.length];
  }

  SongEntity _prevSong() {
    assert(widget.song is SongEntity && widget.songsList.isNotEmpty,
        '_prevSong() must only be called when song is SongEntity and songsList is non-empty');
    final index = _currentIndex();
    return widget.songsList[(index - 1 + widget.songsList.length) % widget.songsList.length];
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
