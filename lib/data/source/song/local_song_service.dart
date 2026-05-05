import 'package:dartz/dartz.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/data/source/song/song_service.dart';
import 'package:museai/domain/entities/song/song_entity.dart';

/// Temporary local catalogue so the app works without a live songs API.
class LocalSongService implements SongService {
  @override
  Future<Either<Failure, List<SongEntity>>> getNewsSongs() async {
    final songs = [
      const SongEntity(
        title: 'Blinding Lights',
        artist: 'The Weeknd',
        duration: 200,
        coverUrl:
            'https://upload.wikimedia.org/wikipedia/en/e/e6/The_Weeknd_-_Blinding_Lights.png',
        songUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      ),
      const SongEntity(
        title: 'Shape of You',
        artist: 'Ed Sheeran',
        duration: 234,
        coverUrl:
            'https://upload.wikimedia.org/wikipedia/en/3/35/Shape_of_You_%28Official_Single_Cover%29_by_Ed_Sheeran.png',
        songUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      ),
      const SongEntity(
        title: 'Levitating',
        artist: 'Dua Lipa',
        duration: 203,
        coverUrl:
            'https://upload.wikimedia.org/wikipedia/en/4/4c/Dua_Lipa_-_Future_Nostalgia_%28Official_Album_Cover%29.png',
        songUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      ),
      const SongEntity(
        title: 'Stay',
        artist: 'The Kid LAROI & Justin Bieber',
        duration: 141,
        coverUrl:
            'https://upload.wikimedia.org/wikipedia/en/9/9b/The_Kid_LAROI_and_Justin_Bieber_-_Stay.png',
        songUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
      ),
      const SongEntity(
        title: 'Bad Guy',
        artist: 'Billie Eilish',
        duration: 194,
        coverUrl:
            'https://upload.wikimedia.org/wikipedia/en/3/32/Billie_Eilish_-_When_We_All_Fall_Asleep%2C_Where_Do_We_Go%3F_%28Official_Album_Cover%29.png',
        songUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
      ),
    ];
    return Right(songs);
  }
}
