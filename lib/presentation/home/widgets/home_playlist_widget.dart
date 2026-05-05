import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:museai/common/helpers/is_dark_mode.dart';
import 'package:museai/domain/entities/song/song_entity.dart';
import 'package:museai/presentation/home/bloc/news_song_cubit.dart';
import 'package:museai/presentation/home/bloc/news_song_state.dart';
import 'package:museai/presentation/song_player/pages/song_player_page.dart';

import '../../../core/configs/themes/app_colors.dart';

class HomePlaylistWidget extends StatelessWidget {
  const HomePlaylistWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
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
            return Container();
          }
          if (songState is NewsSongLoaded) {
            final songs = songState.songs;
            return ListView.separated(
              separatorBuilder: (context, index) => const SizedBox(height: 15),
              itemCount: songs.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                SongEntity song = songs[index];
                return GestureDetector(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>SongPlayerPage(song:song,songsList:songs)));
                  },
                  child: Row(
                    children: [
                      Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.isDarkMode
                              ? AppColors.lightBackgroundColor.withValues(alpha: 0.5)
                              : AppColors.darkBackgroundColor.withValues(alpha: 0.5),
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: !context.isDarkMode
                              ? AppColors.lightBackgroundColor
                              : AppColors.darkBackgroundColor,
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            song.artist ?? 'Unknown Artist',
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        song.duration.toString().replaceAll('.', ':'),
                      ),
                      const SizedBox(width: 20),
                      Icon(
                        Icons.favorite_rounded,
                        color: context.isDarkMode
                            ? AppColors.lightBackgroundColor.withValues(alpha: 0.5)
                            : AppColors.darkBackgroundColor.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                );
              },
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }
}
