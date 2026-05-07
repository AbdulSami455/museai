import 'package:equatable/equatable.dart';

enum PlaylistVisibility { private, public }

class PlaylistEntity extends Equatable {
  final String id;
  final String uid;
  final String name;
  final String? description;
  final PlaylistVisibility visibility;
  final List<String> trackIds;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PlaylistEntity({
    required this.id,
    required this.uid,
    required this.name,
    this.description,
    required this.visibility,
    required this.trackIds,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        uid,
        name,
        description,
        visibility,
        trackIds,
        createdAt,
        updatedAt,
      ];
}
