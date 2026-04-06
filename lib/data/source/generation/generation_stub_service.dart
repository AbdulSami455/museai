import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:museai/core/configs/const/firebase_const.dart';
import 'package:museai/data/models/generation/generation_model.dart';
import 'package:museai/data/source/generation/generation_firebase_service.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/usecases/generation/generation_params.dart';

class GenerationStubService implements GenerationFirebaseService {
  final FirebaseFirestore _firestore;

  GenerationStubService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> createGeneration(String uid, GenerationParams params) async {
    final docRef = _firestore
        .collection(FirebaseConst.generations)
        .doc(uid)
        .collection(FirebaseConst.tracks)
        .doc();

    final model = GenerationModel(
      id: docRef.id,
      uid: uid,
      prompt: params.prompt,
      mood: params.mood,
      genre: params.genre,
      bpm: params.bpm,
      status: GenerationStatus.processing,
      createdAt: DateTime.now(),
    );

    await docRef.set(model.toMap());

    // Simulate backend completing after 3 seconds
    Future.delayed(const Duration(seconds: 3), () async {
      await docRef.update({
        'status': 'completed',
        'audioUrl': 'https://example.com/stub-audio.mp3',
        'coverUrl': 'https://example.com/stub-cover.jpg',
      });
    });

    return docRef.id;
  }

  @override
  Stream<GenerationEntity> watchGeneration(String uid, String generationId) {
    return _firestore
        .collection(FirebaseConst.generations)
        .doc(uid)
        .collection(FirebaseConst.tracks)
        .doc(generationId)
        .snapshots()
        .map(GenerationModel.fromFirestore);
  }

  @override
  Future<List<GenerationEntity>> getUserGenerations(String uid) async {
    final snapshot = await _firestore
        .collection(FirebaseConst.generations)
        .doc(uid)
        .collection(FirebaseConst.tracks)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map(GenerationModel.fromFirestore).toList();
  }
}
