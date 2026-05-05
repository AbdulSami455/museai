import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:museai/common/helpers/is_dark_mode.dart';
import 'package:museai/core/configs/themes/app_colors.dart';
import 'package:museai/presentation/home/bloc/news_song_cubit.dart';
import 'package:museai/presentation/home/bloc/news_song_state.dart';

import '../../../domain/entities/song/song_entity.dart';
import '../../song_player/pages/song_player_page.dart';

class NewsSongsWidget extends StatelessWidget {
  final List<SongEntity>? songs;
  const NewsSongsWidget({super.key, this.songs});

  @override
  Widget build(BuildContext context) {
    if (songs != null) {
      return _songList(context, songs!);
    }

    return SizedBox(
      height: 200,
      child: BlocProvider(
        create: (context) => NewsSongCubit()..getNewsSongs(),
        child: BlocBuilder<NewsSongCubit, NewsSongState>(
          builder: (context, songState) {
            if (songState is NewsSongLoading) {
              return Container(
                alignment: Alignment.center,
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: AppColors.primaryColor,
                  size: 50,
                ),
              );
            }
            if (songState is NewsSongError) {
              return Container(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      songState.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          context.read<NewsSongCubit>().getNewsSongs(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (songState is NewsSongLoaded) {
              return _songList(context, songState.songs);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _songList(BuildContext context, List<SongEntity> songs) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          // Animation 5: Hero tag on the cover image — shared-element transition
          // from the song list card to the full-screen player cover container.
          final heroTag = 'song-cover-${song.title}';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SongPlayerPage(song: song, songsList: songs),
                      ),
                    );
                  },
                  child: Hero(
                    tag: heroTag,
                    child: Container(
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: NetworkImage(song.coverUrl ?? ''),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          height: 30,
                          width: 30,
                          transform: Matrix4.translationValues(5, 8, 0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.isDarkMode
                                ? AppColors.lightBackgroundColor
                                    .withValues(alpha: 0.8)
                                : AppColors.darkBackgroundColor
                                    .withValues(alpha: 0.8),
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: !context.isDarkMode
                                ? AppColors.lightBackgroundColor
                                : AppColors.darkBackgroundColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                song.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                song.artist ?? 'Unknown Artist',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
