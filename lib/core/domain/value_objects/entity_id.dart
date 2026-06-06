final class EntityId {
  const EntityId(this.value);

  final String value;

  bool get isEmpty => value.trim().isEmpty;

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EntityId &&
            runtimeType == other.runtimeType &&
            value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}
