/// Parses a user-entered decimal number accepting both `.` and `,` as the
/// decimal separator (e.g. `12.7` and `12,7`). Returns null for invalid or
/// empty input.
double? parseDecimal(String? input) {
  final normalized = input?.trim().replaceAll(',', '.');
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return double.tryParse(normalized);
}
