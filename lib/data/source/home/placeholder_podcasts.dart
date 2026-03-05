import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spotify_clone/domain/entities/song/song_entity.dart';

class PlaceholderPodcasts {
  static List<SongEntity> get items => [
        SongEntity(
          title: 'Tech Talks Daily',
          artist: 'DevCast Studio',
          duration: 42.18,
          releaseDate: Timestamp.now(),
          coverUrl: 'https://picsum.photos/seed/podcast-1/500/500',
          songUrl:
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
        ),
        SongEntity(
          title: 'Startup Stories',
          artist: 'Growth FM',
          duration: 35.41,
          releaseDate: Timestamp.now(),
          coverUrl: 'https://picsum.photos/seed/podcast-2/500/500',
          songUrl:
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
        ),
        SongEntity(
          title: 'Mindful Minutes',
          artist: 'Calm Sphere',
          duration: 28.09,
          releaseDate: Timestamp.now(),
          coverUrl: 'https://picsum.photos/seed/podcast-3/500/500',
          songUrl:
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
        ),
        SongEntity(
          title: 'Design Breakdown',
          artist: 'Pixel Room',
          duration: 31.52,
          releaseDate: Timestamp.now(),
          coverUrl: 'https://picsum.photos/seed/podcast-4/500/500',
          songUrl:
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3',
        ),
      ];
}
