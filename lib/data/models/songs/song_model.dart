import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:museai/domain/entities/song/song_entity.dart';

class SongModel extends SongEntity {
  const SongModel({super.coverUrl, super.songUrl, super.title, super.artist, super.duration, super.releaseDate});

  factory SongModel.fromSnapshot(DocumentSnapshot snap) {
     var snapshot = snap.data() as Map<String, dynamic>;
    return SongModel(
      title: snapshot['title'],
      artist: snapshot['artist'],
      duration: snapshot['duration'],
      releaseDate: snapshot['releaseDate'],
      songUrl: snapshot['songUrl'],
      coverUrl: snapshot['coverUrl'],
    );
  }
}
