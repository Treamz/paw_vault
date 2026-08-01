import 'dart:ui' as ui;

import 'package:intl/intl.dart';

/// Formats [value] for display using the decimal separator of the device
/// locale (matching what the numeric keyboard offers), without grouping.
String formatDecimal(double value, {int maxDecimals = 2}) {
  final locale = ui.PlatformDispatcher.instance.locale.toLanguageTag();
  try {
    final format = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = 0
      ..maximumFractionDigits = maxDecimals
      ..turnOffGrouping();
    return format.format(value);
  } catch (_) {
    return value % 1 == 0 ? value.toInt().toString() : value.toString();
  }
}

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
