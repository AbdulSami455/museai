import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:museai/common/helpers/is_dark_mode.dart';
import 'package:museai/common/widgets/appbar/app_bar_widget.dart';
import 'package:museai/domain/entities/song/song_entity.dart';
import 'package:museai/presentation/song_player/bloc/song_player_cubit.dart';
import 'package:museai/presentation/song_player/bloc/song_player_state.dart';

import '../../../core/configs/themes/app_colors.dart';

class SongPlayerPage extends StatelessWidget {
  final List<SongEntity> songsList;
  final SongEntity song;
  const SongPlayerPage(
      {super.key, required this.song, required this.songsList});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWidget(
        title: Text(
          'Now Playing',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: BlocProvider(
        create: (_) => SongPlayerCubit()..loadSong(song),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Builder(builder: (context) {
            return Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      image: DecorationImage(
                        image: NetworkImage(song.coverUrl!),
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
                            song.title!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            song.artist!,
                            style: const TextStyle(
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.favorite_border_rounded,
                        color: context.isDarkMode
                            ? AppColors.lightBackgroundColor.withOpacity(0.5)
                            : AppColors.darkBackgroundColor.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
                songPlayerWidget(context),
              ],
            );
          }),
        ),
      ),
    );
  }

  songPlayerWidget(BuildContext context) {
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
          return Container();
        }
        if (songState is SongPlayerLoaded) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Slider(
                activeColor: AppColors.primaryColor,
                value: context
                    .read<SongPlayerCubit>()
                    .songPosition
                    .inSeconds
                    .toDouble(),
                min: 0.0,
                max: context
                    .read<SongPlayerCubit>()
                    .songDuration
                    .inSeconds
                    .toDouble(),
                onChanged: (value) {
                  final duration = Duration(seconds: value.toInt());
                  context.read<SongPlayerCubit>().jumpTo(duration);
                },
              ),
              const SizedBox(
                height: 5,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _foramtDuration(
                        context.read<SongPlayerCubit>().songPosition),
                  ),
                  Text(
                    _foramtDuration(
                        context.read<SongPlayerCubit>().songDuration),
                  ),
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
                            song: playPrevSong(),
                            songsList: songsList,
                          ),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.skip_previous_rounded,
                      size: 30,
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  GestureDetector(
                    onTap: () {
                      context.read<SongPlayerCubit>().playOrPauseSong();
                    },
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryColor,
                      ),
                      child: Icon(
                        context.read<SongPlayerCubit>().audioPlayer.playing
                            ? Icons.pause_sharp
                            : Icons.play_arrow_rounded,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  GestureDetector(
                    onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SongPlayerPage(
                                song: playNextSong(),
                                songsList: songsList,
                              ),
                            ),
                          );
                        },
                    child: const Icon(
                      Icons.skip_next_rounded,
                      size: 30,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          return Container();
        }
      },
    );
  }

  SongEntity playNextSong() {
    final currentIndex = songsList.indexOf(song);
    final nextIndex = (currentIndex + 1) % songsList.length;
    final nextSong = songsList[nextIndex];
    return nextSong;
  }
  SongEntity playPrevSong() {
    final currentIndex = songsList.indexOf(song);
    final nextIndex = (currentIndex - 1) % songsList.length;
    final nextSong = songsList[nextIndex];
    return nextSong;
  }

  String _foramtDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
