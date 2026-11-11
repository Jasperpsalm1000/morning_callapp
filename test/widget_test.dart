import 'package:flutter_test/flutter_test.dart';
import 'package:morning_call/services/sentiment_service.dart';

void main() {
  test('happy text is positive', () {
    final r = SentimentService.analyze(
      'Yesterday was great, I finished my project and felt happy.',
    );
    expect(r.label, 'positive');
    expect(r.score, greaterThan(0.2));
  });

  test('sad text is negative', () {
    final r = SentimentService.analyze(
      'It was a terrible day, I felt sad and stressed.',
    );
    expect(r.label, 'negative');
    expect(r.score, lessThan(-0.2));
  });

  test('plain text is neutral', () {
    final r = SentimentService.analyze('It was an ordinary day, nothing special.');
    expect(r.label, 'neutral');
  });

  test('negation flips the meaning', () {
    expect(SentimentService.analyze('I was not happy.').label, 'negative');
    expect(SentimentService.analyze('It was not bad.').label, 'positive');
  });

  test('empty text is neutral', () {
    expect(SentimentService.analyze('').label, 'neutral');
  });
}
