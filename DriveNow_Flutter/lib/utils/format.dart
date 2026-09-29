const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const _longMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// 7500 -> "₱7,500"
String peso(num amount) {
  final whole = amount.round().abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
    buf.write(whole[i]);
  }
  return '${amount < 0 ? '-' : ''}₱$buf';
}

String _two(int n) => n.toString().padLeft(2, '0');

String _time(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${_two(d.minute)} ${d.hour < 12 ? 'AM' : 'PM'}';
}

/// "Oct 15, 2025 at 3:30 PM" (like Swift's .abbreviated / .shortened)
String dateTimeShort(DateTime d) =>
    '${_months[d.month - 1]} ${d.day}, ${d.year} at ${_time(d)}';

/// "Oct 15, 2025"
String dateMedium(DateTime d) =>
    '${_months[d.month - 1]} ${_two(d.day)}, ${d.year}';

/// "October 15, 2025"
String dateLong(DateTime d) => '${_longMonths[d.month - 1]} ${d.day}, ${d.year}';

/// "10/15/25, 3:30 PM"
String dateTimeCompact(DateTime d) =>
    '${d.month}/${d.day}/${_two(d.year % 100)}, ${_time(d)}';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// "3:30 PM"
String timeShort(DateTime d) => _time(d);

/// "Wed, Oct 15"
String dayMonth(DateTime d) => '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';

/// "Oct 15"
String monthDay(DateTime d) => '${_months[d.month - 1]} ${d.day}';

/// "Good morning" / "Good afternoon" / "Good evening"
String greeting([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}

/// "2 days", "1 day"
String plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';
