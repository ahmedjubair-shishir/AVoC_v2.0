import 'package:avoc/features/recordings/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatDuration', () {
    expect(formatDuration(const Duration(seconds: 47)), '00:47');
    expect(formatDuration(const Duration(minutes: 1, seconds: 12)), '01:12');
  });

  test('formatRelativeDate', () {
    final now = DateTime(2026, 10, 9, 12);
    expect(formatRelativeDate(DateTime(2026, 10, 9, 8), now: now), 'Today');
    expect(formatRelativeDate(DateTime(2026, 10, 8), now: now), 'Yesterday');
    expect(formatRelativeDate(DateTime(2026, 10, 6), now: now), 'Oct 6');
  });
}
