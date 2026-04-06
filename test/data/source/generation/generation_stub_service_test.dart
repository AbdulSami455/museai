import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museai/data/source/generation/generation_stub_service.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/usecases/generation/generation_params.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late GenerationStubService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = GenerationStubService(firestore: fakeFirestore);
  });

  const params = GenerationParams(
    uid: 'user-123',
    prompt: 'test track',
    mood: 'Happy',
    genre: 'Pop',
    bpm: 120,
  );

  test('createGeneration writes doc with status processing', () async {
    final id = await service.createGeneration('user-123', params);

    expect(id, isNotEmpty);

    final doc = await fakeFirestore
        .collection('generations')
        .doc('user-123')
        .collection('tracks')
        .doc(id)
        .get();

    expect(doc.exists, true);
    expect(doc.data()!['status'], 'processing');
    expect(doc.data()!['prompt'], 'test track');
    expect(doc.data()!['uid'], 'user-123');
  });

  test('watchGeneration emits entity with processing status', () async {
    final id = await service.createGeneration('user-123', params);

    final stream = service.watchGeneration('user-123', id);

    final entity = await stream.first;
    expect(entity.status, GenerationStatus.processing);
    expect(entity.id, id);
    expect(entity.prompt, 'test track');
  });

  test('getUserGenerations returns list after creation', () async {
    await service.createGeneration('user-123', params);
    await service.createGeneration('user-123', params);

    final results = await service.getUserGenerations('user-123');
    expect(results.length, 2);
  });
}
