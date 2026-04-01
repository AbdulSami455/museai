import 'package:equatable/equatable.dart';

enum GenerationStatus { processing, completed, failed }

class GenerationEntity extends Equatable {
  final String id;
  final String uid;
  final String prompt;
  final String mood;
  final String genre;
  final int bpm;
  final GenerationStatus status;
  final String? audioUrl;
  final String? coverUrl;
  final DateTime createdAt;
  final String? errorMessage;

  const GenerationEntity({
    required this.id,
    required this.uid,
    required this.prompt,
    required this.mood,
    required this.genre,
    required this.bpm,
    required this.status,
    required this.createdAt,
    this.audioUrl,
    this.coverUrl,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        id, uid, prompt, mood, genre, bpm,
        status, audioUrl, coverUrl, createdAt, errorMessage,
      ];
}
