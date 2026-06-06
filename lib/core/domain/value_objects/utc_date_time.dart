final class UtcDateTime implements Comparable<UtcDateTime> {
  UtcDateTime(DateTime value) : value = value.toUtc();

  const UtcDateTime.unchecked(this.value);

  final DateTime value;

  @override
  int compareTo(UtcDateTime other) => value.compareTo(other.value);

  @override
  String toString() => value.toIso8601String();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UtcDateTime &&
            runtimeType == other.runtimeType &&
            value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}
