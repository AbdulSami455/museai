import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';

class GenerationModel extends GenerationEntity {
  const GenerationModel({
    required super.id,
    required super.uid,
    required super.prompt,
    required super.mood,
    required super.genre,
    required super.bpm,
    required super.status,
    required super.createdAt,
    super.audioUrl,
    super.coverUrl,
    super.errorMessage,
  });

  factory GenerationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GenerationModel(
      id: doc.id,
      uid: data['uid'] as String,
      prompt: data['prompt'] as String,
      mood: data['mood'] as String,
      genre: data['genre'] as String,
      bpm: data['bpm'] as int,
      status: _parseStatus(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      audioUrl: data['audioUrl'] as String?,
      coverUrl: data['coverUrl'] as String?,
      errorMessage: data['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'prompt': prompt,
      'mood': mood,
      'genre': genre,
      'bpm': bpm,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'audioUrl': audioUrlNullable,
      'coverUrl': coverUrl,
      'errorMessage': errorMessage,
    };
  }

  static GenerationStatus _parseStatus(String? value) {
    switch (value) {
      case 'completed':
        return GenerationStatus.completed;
      case 'failed':
        return GenerationStatus.failed;
      default:
        return GenerationStatus.processing;
    }
  }
}
