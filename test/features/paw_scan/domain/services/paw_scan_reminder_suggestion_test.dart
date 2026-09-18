import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_attention_level.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_check.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_location.dart';
import 'package:paw_vault/features/paw_scan/domain/services/paw_scan_reminder_suggestion.dart';

PawCheck _check(PawAttentionLevel level) {
  return PawCheck(
    id: const EntityId('check-1'),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    location: PawLocation.frontLeft,
    attentionLevel: level,
    checkedAt: UtcDateTime(DateTime.utc(2026, 9, 18, 12)),
    status: PawCheckStatus.confirmed,
  );
}

void main() {
  group('PawScanReminderSuggestion.forCheck', () {
    final now = DateTime(2026, 9, 18, 12);

    test('suggests nothing when nothing stood out', () {
      expect(
        PawScanReminderSuggestion.forCheck(
          _check(PawAttentionLevel.nothingNotable),
          petName: 'Bella',
          now: now,
        ),
        isNull,
      );
    });

    test('suggests nothing when the level could not be established', () {
      // An unreadable photo is not a reason to propose a vet visit.
      expect(
        PawScanReminderSuggestion.forCheck(
          _check(PawAttentionLevel.undetermined),
          petName: 'Bella',
          now: now,
        ),
        isNull,
      );
    });

    test('suggests a re-check in three days to monitor', () {
      final suggestion = PawScanReminderSuggestion.forCheck(
        _check(PawAttentionLevel.monitor),
        petName: 'Bella',
        now: now,
      )!;

      expect(suggestion.title, "Re-check Bella's paw");
      expect(suggestion.dateTime, DateTime(2026, 9, 21, 12));
      expect(suggestion.description, contains('compare'));
      expect(suggestion.description, contains('18 Sep 2026'));
    });

    test('suggests booking a vet visit in two days for vetSoon', () {
      final suggestion = PawScanReminderSuggestion.forCheck(
        _check(PawAttentionLevel.vetSoon),
        petName: 'Bella',
        now: now,
      )!;

      expect(suggestion.title, "Book a vet visit for Bella's paw");
      expect(suggestion.dateTime, DateTime(2026, 9, 20, 12));
    });

    test('suggests calling the vet within hours for vetPromptly', () {
      final suggestion = PawScanReminderSuggestion.forCheck(
        _check(PawAttentionLevel.vetPromptly),
        petName: 'Bella',
        now: now,
      )!;

      expect(suggestion.title, "Call the vet about Bella's paw");
      expect(suggestion.dateTime, DateTime(2026, 9, 18, 16));
    });

    test('never names a condition or suggests treatment', () {
      for (final level in PawAttentionLevel.values) {
        final suggestion = PawScanReminderSuggestion.forCheck(
          _check(level),
          petName: 'Bella',
          now: now,
        );
        if (suggestion == null) continue;

        final text = '${suggestion.title} ${suggestion.description}';
        for (final forbidden in [
          'infection',
          'treat',
          'medication',
          'apply',
          'diagnos',
        ]) {
          expect(
            text.toLowerCase(),
            isNot(contains(forbidden)),
            reason: '$level should not mention "$forbidden"',
          );
        }
      }
    });

    group('keeps reminders out of the night', () {
      test('moves a late-evening time to the next morning', () {
        // 19:00 + 4h = 23:00, past the 22:00 cutoff.
        final suggestion = PawScanReminderSuggestion.forCheck(
          _check(PawAttentionLevel.vetPromptly),
          petName: 'Bella',
          now: DateTime(2026, 9, 18, 19),
        )!;

        expect(suggestion.dateTime, DateTime(2026, 9, 19, 8));
      });

      test('moves a time that rolls past midnight to that morning', () {
        // 23:00 + 4h = 03:00 the next day.
        final suggestion = PawScanReminderSuggestion.forCheck(
          _check(PawAttentionLevel.vetPromptly),
          petName: 'Bella',
          now: DateTime(2026, 9, 18, 23),
        )!;

        expect(suggestion.dateTime, DateTime(2026, 9, 19, 8));
      });

      test('moves an early-morning time to 8am the same day', () {
        final suggestion = PawScanReminderSuggestion.forCheck(
          _check(PawAttentionLevel.vetPromptly),
          petName: 'Bella',
          now: DateTime(2026, 9, 18, 1),
        )!;

        expect(suggestion.dateTime, DateTime(2026, 9, 18, 8));
      });

      test('leaves a daytime time alone', () {
        final suggestion = PawScanReminderSuggestion.forCheck(
          _check(PawAttentionLevel.vetPromptly),
          petName: 'Bella',
          now: DateTime(2026, 9, 18, 9),
        )!;

        expect(suggestion.dateTime, DateTime(2026, 9, 18, 13));
      });
    });
  });
}
