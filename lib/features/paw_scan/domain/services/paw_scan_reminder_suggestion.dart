import 'package:paw_vault/features/paw_scan/domain/entities/paw_attention_level.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_check.dart';

/// A pre-filled follow-up reminder for a logged paw check.
///
/// Computed on-device from the attention level, deliberately **not** asked of
/// the model: choosing when someone should see a vet is advice, and advice is
/// the one thing Paw Scan must not generate. The owner still saves the real
/// reminder form themselves, so nothing is scheduled without them.
class PawScanReminderSuggestion {
  const PawScanReminderSuggestion({
    required this.title,
    required this.description,
    required this.dateTime,
  });

  final String title;
  final String description;

  /// Local time, so it lands where the owner expects it in the form.
  final DateTime dateTime;

  /// Returns `null` for [PawAttentionLevel.nothingNotable] and
  /// [PawAttentionLevel.undetermined] — there is nothing to follow up, and
  /// suggesting a vet visit off the back of an unreadable photo would be
  /// inventing a concern. The owner can still add a reminder by hand.
  static PawScanReminderSuggestion? forCheck(
    PawCheck check, {
    required String petName,
    required DateTime now,
  }) {
    final on = _formatDate(check.checkedAt.value.toLocal());

    return switch (check.attentionLevel) {
      PawAttentionLevel.nothingNotable ||
      PawAttentionLevel.undetermined =>
        null,
      PawAttentionLevel.monitor => PawScanReminderSuggestion(
          title: "Re-check $petName's paw",
          description: 'Take another paw check and compare it with the one '
              'from $on.',
          dateTime: _clampToWakingHours(now.add(const Duration(days: 3))),
        ),
      PawAttentionLevel.vetSoon => PawScanReminderSuggestion(
          title: "Book a vet visit for $petName's paw",
          description: 'The paw check on $on was worth showing to a vet.',
          dateTime: _clampToWakingHours(now.add(const Duration(days: 2))),
        ),
      PawAttentionLevel.vetPromptly => PawScanReminderSuggestion(
          title: "Call the vet about $petName's paw",
          description: 'The paw check on $on was flagged for prompt '
              'attention.',
          dateTime: _clampToWakingHours(now.add(const Duration(hours: 4))),
        ),
    };
  }

  /// Moves a reminder out of the middle of the night, where a notification
  /// would be missed or unwelcome.
  static DateTime _clampToWakingHours(DateTime value) {
    if (value.hour >= 22) {
      final nextMorning = value.add(const Duration(days: 1));
      return DateTime(
        nextMorning.year,
        nextMorning.month,
        nextMorning.day,
        8,
      );
    }

    if (value.hour < 8) {
      return DateTime(value.year, value.month, value.day, 8);
    }

    return value;
  }

  static String _formatDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }
}
