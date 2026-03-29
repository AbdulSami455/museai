import 'package:flutter_test/flutter_test.dart';
import 'package:museai/core/error/failures.dart';

void main() {
  group('AuthFailure', () {
    test('two AuthFailures with same code and message are equal', () {
      const f1 = AuthFailure(code: AuthErrorCode.weakPassword, message: 'too weak');
      const f2 = AuthFailure(code: AuthErrorCode.weakPassword, message: 'too weak');
      expect(f1, equals(f2));
    });

    test('AuthFailures with different codes are not equal', () {
      const f1 = AuthFailure(code: AuthErrorCode.weakPassword, message: 'msg');
      const f2 = AuthFailure(code: AuthErrorCode.invalidEmail, message: 'msg');
      expect(f1, isNot(equals(f2)));
    });
  });

  group('SongFailure', () {
    test('two SongFailures with same message are equal', () {
      const f1 = SongFailure(message: 'not found');
      const f2 = SongFailure(message: 'not found');
      expect(f1, equals(f2));
    });
  });

  group('NetworkFailure', () {
    test('two NetworkFailures with same message are equal', () {
      const f1 = NetworkFailure(message: 'no internet');
      const f2 = NetworkFailure(message: 'no internet');
      expect(f1, equals(f2));
    });
  });
}
