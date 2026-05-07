// This widget renders a reusable piece of the home screen.

import 'package:flutter/material.dart';
import 'package:museai/data/source/home/placeholder_artists.dart';

class HomeArtistsTabWidget extends StatelessWidget {
  const HomeArtistsTabWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final artists = PlaceholderArtists.items;
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: artists.length,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (context, index) {
        final artist = artists[index];
        return SizedBox(
          width: 110,
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(artist.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                artist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                artist.genre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }
}
