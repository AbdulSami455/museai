import 'package:museai/domain/entities/song/song_entity.dart';

class SongModel extends SongEntity {
  const SongModel({
    super.title,
    super.artist,
    super.duration,
    super.releaseDate,
    super.coverUrl,
    super.songUrl,
  });

  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel(
      title: map['title'] as String?,
      artist: map['artist'] as String?,
      duration: map['duration'] as num?,
      songUrl: map['song_url'] as String?,
      coverUrl: map['cover_url'] as String?,
      releaseDate: map['release_date'] != null
          ? DateTime.parse(map['release_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': titleNullable,
      'artist': artistNullable,
      'duration': duration,
      'song_url': songUrl,
      'cover_url': coverUrl,
      'release_date': releaseDate?.toIso8601String(),
    };
  }
}
