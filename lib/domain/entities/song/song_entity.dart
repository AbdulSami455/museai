import 'package:equatable/equatable.dart';
import 'package:museai/domain/entities/playable.dart';

class SongEntity extends Equatable implements Playable {
  final String? titleNullable;
  final String? artistNullable;
  final num? duration;
  final DateTime? releaseDate;
  final String? _coverUrl;
  final String? songUrl;

  const SongEntity({
    String? title,
    String? artist,
    this.duration,
    this.releaseDate,
    String? coverUrl,
    this.songUrl,
  })  : titleNullable = title,
        artistNullable = artist,
        _coverUrl = coverUrl;

  @override
  String get audioUrl => songUrl ?? '';

  @override
  String get title => titleNullable ?? 'Unknown';

  @override
  String? get artist => artistNullable;

  @override
  String? get coverUrl => _coverUrl;

  @override
  List<Object?> get props => [
        titleNullable,
        artistNullable,
        duration,
        releaseDate,
        _coverUrl,
        songUrl,
      ];
}
