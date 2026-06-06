final class DateOnly implements Comparable<DateOnly> {
  const DateOnly({
    required this.year,
    required this.month,
    required this.day,
  });

  factory DateOnly.fromDateTime(DateTime value) {
    final localValue = value.toLocal();
    return DateOnly(
      year: localValue.year,
      month: localValue.month,
      day: localValue.day,
    );
  }

  final int year;
  final int month;
  final int day;

  DateTime toUtcDateTime() => DateTime.utc(year, month, day);

  @override
  int compareTo(DateOnly other) {
    return toUtcDateTime().compareTo(other.toUtcDateTime());
  }

  @override
  String toString() {
    final paddedMonth = month.toString().padLeft(2, '0');
    final paddedDay = day.toString().padLeft(2, '0');
    return '$year-$paddedMonth-$paddedDay';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DateOnly &&
            runtimeType == other.runtimeType &&
            year == other.year &&
            month == other.month &&
            day == other.day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);
}
