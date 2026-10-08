/// "00:47", "01:12"
String formatDuration(Duration d) {
  final m = d.inMinutes.remainder(100).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// "1:36" (used for "1:36 remaining")
String formatShort(Duration d) {
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${d.inMinutes}:$s';
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Today", "Yesterday", or "Oct 6"
String formatRelativeDate(DateTime date, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  final sameYear = date.year == n.year;
  return '${_months[date.month - 1]} ${date.day}${sameYear ? '' : ', ${date.year}'}';
}

/// "7:20 PM"
String formatTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
}

/// "Today, 7:20 PM"
String formatDateTime(DateTime t, {DateTime? now}) =>
    '${formatRelativeDate(t, now: now)}, ${formatTime(t)}';

/// Keeps names safe and readable as file names.
String safeFileName(String name) {
  final cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '').trim();
  return cleaned.isEmpty ? 'Voice Recording' : cleaned;
}
