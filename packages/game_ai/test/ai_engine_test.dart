import 'package:game_ai/game_ai.dart';
import 'package:test/test.dart';

void main() {
  test('AiDifficulty üç seviye tanımlı', () {
    expect(AiDifficulty.values, hasLength(3));
    expect(AiDifficulty.values, contains(AiDifficulty.easy));
    expect(AiDifficulty.values, contains(AiDifficulty.medium));
    expect(AiDifficulty.values, contains(AiDifficulty.hard));
  });
}
