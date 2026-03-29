import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:museai/domain/entities/song/song_entity.dart';

class SongModel extends SongEntity {
  final String? title;
  final String? artist;
  final num? duration;
  final Timestamp? releaseDate;
  final String? coverUrl;
  final String? songUrl;

  const SongModel({this.coverUrl, this.songUrl, this.title, this.artist, this.duration, this.releaseDate});

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
