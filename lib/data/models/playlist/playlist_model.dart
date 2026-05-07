// This model maps raw data into app structures for playlist features.

import 'package:museai/domain/entities/playlist/playlist_entity.dart';

class PlaylistModel extends PlaylistEntity {
  const PlaylistModel({
    required super.id,
    required super.uid,
    required super.name,
    super.description,
    required super.visibility,
    required super.trackIds,
    required super.createdAt,
    super.updatedAt,
  });

  factory PlaylistModel.fromMap(Map<String, dynamic> map) {
    return PlaylistModel(
      id: map['id'] as String,
      uid: map['uid'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      visibility: (map['visibility'] as String?) == 'public'
          ? PlaylistVisibility.public
          : PlaylistVisibility.private,
      trackIds: ((map['track_ids'] as List?) ?? const []).cast<String>(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
