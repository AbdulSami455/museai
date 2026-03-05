import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spotify_clone/domain/entities/song/song_entity.dart';

class PlaceholderSongs {
  static List<SongEntity> get items => [
        SongEntity(
          title: 'Skyline Drive',
          artist: 'Nova Lane',
          duration: 3.34,
          releaseDate: Timestamp.now(),
          coverUrl: 'https://picsum.photos/seed/spotify-clone-1/500/500',
          songUrl:
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        ),
        SongEntity(
          title: 'Midnight Echo',
          artist: 'Aria Vale',
          duration: 4.02,
          releaseDate: Timestamp.now(),
          coverUrl: 'https://picsum.photos/seed/spotify-clone-2/500/500',
          songUrl:
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        ),
        SongEntity(
          title: 'Golden Hour',
          artist: 'Rey Carter',
          duration: 2.58,
          releaseDate: Timestamp.now(),
          coverUrl: 'https://picsum.photos/seed/spotify-clone-3/500/500',
          songUrl:
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        ),
        SongEntity(
          title: 'City Lights',
          artist: 'Luna Park',
          duration: 3.16,
          releaseDate: Timestamp.now(),
          coverUrl: 'https://picsum.photos/seed/spotify-clone-4/500/500',
          songUrl:
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
        ),
        SongEntity(
          title: 'Ocean Air',
          artist: 'Kai Rivers',
          duration: 3.47,
          releaseDate: Timestamp.now(),
          coverUrl: 'https://picsum.photos/seed/spotify-clone-5/500/500',
          songUrl:
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
        ),
      ];
}
