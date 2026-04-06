import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:museai/common/helpers/is_dark_mode.dart';
import 'package:museai/common/widgets/appbar/app_bar_widget.dart';
import 'package:museai/core/configs/themes/app_colors.dart';
import 'package:museai/domain/entities/song/song_entity.dart';
import 'package:museai/presentation/song_player/bloc/song_player_cubit.dart';
import 'package:museai/presentation/song_player/bloc/song_player_state.dart';
import 'package:museai/service_locator.dart';

class SongPlayerPage extends StatefulWidget {
  final List<SongEntity> songsList;
  final SongEntity song;
  const SongPlayerPage({super.key, required this.song, required this.songsList});

  @override
  State<SongPlayerPage> createState() => _SongPlayerPageState();
}

class _SongPlayerPageState extends State<SongPlayerPage> {
  @override
  void initState() {
    super.initState();
    sl<SongPlayerCubit>().loadSong(widget.song);
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
                    image: DecorationImage(
                      image: NetworkImage(widget.song.coverUrl!),
                      fit: BoxFit.cover,
                    ),
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
                          widget.song.title!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.song.artist!,
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
                    child: const Icon(Icons.skip_previous_rounded, size: 30, color: AppColors.grey),
                  ),
                  const SizedBox(width: 15),
                  GestureDetector(
                    onTap: () => sl<SongPlayerCubit>().playOrPauseSong(),
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryColor,
                      ),
                      child: Icon(
                        sl<SongPlayerCubit>().audioPlayer.playing
                            ? Icons.pause_sharp
                            : Icons.play_arrow_rounded,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
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
                    child: const Icon(Icons.skip_next_rounded, size: 30, color: AppColors.grey),
                  ),
                ],
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  SongEntity _nextSong() {
    final index = widget.songsList.indexOf(widget.song);
    return widget.songsList[(index + 1) % widget.songsList.length];
  }

  SongEntity _prevSong() {
    final index = widget.songsList.indexOf(widget.song);
    return widget.songsList[(index - 1) % widget.songsList.length];
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
