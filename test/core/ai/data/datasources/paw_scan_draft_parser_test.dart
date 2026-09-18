import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/ai/data/datasources/flutter_fire_ai_logic_data_source.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_attention_level.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_location.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_observation.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_scan_draft.dart';
import 'package:paw_vault/features/paw_scan/domain/services/paw_scan_safety_filter.dart';

String _reply(Map<String, Object?> json) => jsonEncode(json);

Map<String, Object?> _validReply({
  Object? attentionLevel = 'monitor',
  List<Map<String, Object?>>? observations,
  Object? confidence = 0.82,
  Object? isPaw = true,
  Object? photoQuality = 'usable',
  Object? summary = 'One pad looks different from the others.',
}) {
  return {
    'isPaw': isPaw,
    'photoQuality': photoQuality,
    'observations': observations ??
        [
          {'area': 'pad', 'text': 'A dark area near the centre of the pad.'},
        ],
    'attentionLevel': attentionLevel,
    'summary': summary,
    'confidence': confidence,
  };
}

void main() {
  group('parsePawScanDraft', () {
    test('parses a complete reply', () {
      final draft = FlutterFireAiLogicDataSource.parsePawScanDraft(
        _reply(_validReply()),
        requestedLocation: PawLocation.frontLeft,
      );

      expect(draft.status, PawScanDraftStatus.awaitingReview);
      expect(draft.attentionLevel, PawAttentionLevel.monitor);
      expect(draft.confidence, 0.82);
      expect(draft.summary, 'One pad looks different from the others.');
      expect(draft.observations.single.area, PawObservationArea.pad);
      expect(
        draft.observations.single.text,
        'A dark area near the centre of the pad.',
      );
      expect(draft.requiresConfirmation, isTrue);
      expect(draft.canBeLogged, isTrue);
    });

    test('strips json code fences', () {
      final draft = FlutterFireAiLogicDataSource.parsePawScanDraft(
        '```json\n${_reply(_validReply())}\n```',
      );

      expect(draft.status, PawScanDraftStatus.awaitingReview);
      expect(draft.attentionLevel, PawAttentionLevel.monitor);
    });

    test('keeps the owner\'s paw and ignores any the model supplies', () {
      final reply = _validReply()..['location'] = 'rearRight';

      final draft = FlutterFireAiLogicDataSource.parsePawScanDraft(
        _reply(reply),
        requestedLocation: PawLocation.frontLeft,
      );

      expect(draft.location, PawLocation.frontLeft);
    });

    test('accepts snake_case and spaced enum values', () {
      for (final value in ['vet_promptly', 'VET PROMPTLY', 'vet-promptly']) {
        final draft = FlutterFireAiLogicDataSource.parsePawScanDraft(
          _reply(_validReply(attentionLevel: value)),
        );

        expect(
          draft.attentionLevel,
          PawAttentionLevel.vetPromptly,
          reason: value,
        );
      }
    });

    group('rejects the scan without showing a verdict', () {
      test('when the photo is not a paw', () {
        final draft = FlutterFireAiLogicDataSource.parsePawScanDraft(
          _reply(_validReply(isPaw: false, attentionLevel: 'nothingNotable')),
        );

        expect(draft.status, PawScanDraftStatus.unusablePhoto);
        expect(draft.photoQuality, PawScanPhotoQuality.notAPaw);
        expect(draft.attentionLevel, PawAttentionLevel.undetermined);
        expect(draft.observations, isEmpty);
        expect(draft.isUsable, isFalse);
        expect(draft.canBeLogged, isFalse);
      });

      test('for each unusable photo quality', () {
        const unusable = {
          'blurry': PawScanPhotoQuality.blurry,
          'tooDark': PawScanPhotoQuality.tooDark,
          'tooFarAway': PawScanPhotoQuality.tooFarAway,
          'notAPaw': PawScanPhotoQuality.notAPaw,
        };

        for (final entry in unusable.entries) {
          final draft = FlutterFireAiLogicDataSource.parsePawScanDraft(
            _reply(_validReply(photoQuality: entry.key)),
          );

          expect(
            draft.status,
            PawScanDraftStatus.unusablePhoto,
            reason: entry.key,
          );
          expect(draft.photoQuality, entry.value, reason: entry.key);
          expect(draft.observations, isEmpty, reason: entry.key);
        }
      });
    });

    group('never fabricates reassurance', () {
      test('an unparseable reply is undetermined, not "nothing notable"', () {
        for (final text in [
          null,
          '',
          '   ',
          'I am unable to help with that.',
          '{"isPaw": ',
          '[]',
        ]) {
          final draft = FlutterFireAiLogicDataSource.parsePawScanDraft(text);

          expect(
            draft.attentionLevel,
            PawAttentionLevel.undetermined,
            reason: 'input: $text',
          );
          expect(
            draft.attentionLevel,
            isNot(PawAttentionLevel.nothingNotable),
            reason: 'input: $text',
          );
          expect(draft.status, PawScanDraftStatus.lowConfidenceReview);
          expect(draft.requiresConfirmation, isTrue);
        }
      });

      test('a missing or unknown attention level is undetermined', () {
        for (final value in [null, 'panic', 'fine', 'healthy', 'ok']) {
          final draft = FlutterFireAiLogicDataSource.parsePawScanDraft(
            _reply(_validReply(attentionLevel: value)),
          );

          expect(
            draft.attentionLevel,
            PawAttentionLevel.undetermined,
            reason: value,
          );
          expect(draft.status, PawScanDraftStatus.lowConfidenceReview);
        }
      });

      test('preserves the owner\'s paw through a parse failure', () {
        final draft = FlutterFireAiLogicDataSource.parsePawScanDraft(
          'not json',
          requestedLocation: PawLocation.rearLeft,
        );

        expect(draft.location, PawLocation.rearLeft);
      });
    });

    group('confidence', () {
      test('below the threshold downgrades to low-confidence review', () {
        final draft = FlutterFireAiLogicDataSource.parsePawScanDraft(
          _reply(_validReply(confidence: 0.3)),
        );

        expect(draft.status, PawScanDraftStatus.lowConfidenceReview);
        expect(draft.isLowConfidence, isTrue);
        // Still reviewable — a weak description is not a rejection.
        expect(draft.canBeLogged, isTrue);
      });

      test('a missing confidence is not treated as low', () {
        final draft = FlutterFireAiLogicDataSource.parsePawScanDraft(
          _reply(_validReply(confidence: null)),
        );

        expect(draft.confidence, isNull);
        expect(draft.isLowConfidence, isFalse);
        expect(draft.status, PawScanDraftStatus.awaitingReview);
      });
    });

    group('malformed observations degrade instead of throwing', () {
      test('skips entries that are not objects or have no text', () {
        final draft = FlutterFireAiLogicDataSource.parsePawScanDraft(
          _reply(
            _validReply(
              observations: [
                {'area': 'pad', 'text': 'A dark area on the pad.'},
                {'area': 'nail', 'text': ''},
                {'area': 'nail'},
              ],
            ),
          ),
        );

        expect(draft.observations, hasLength(1));
        expect(draft.observations.single.text, 'A dark area on the pad.');
      });

      test('falls back to the overall area for an unknown area', () {
        final draft = FlutterFireAiLogicDataSource.parsePawScanDraft(
          _reply(
            _validReply(
              observations: [
                {'area': 'elbow', 'text': 'Something on the paw.'},
              ],
            ),
          ),
        );

        expect(draft.observations.single.area, PawObservationArea.overall);
      });

      test('tolerates observations that are not a list', () {
        final reply = _validReply()..['observations'] = 'none';

        final draft =
            FlutterFireAiLogicDataSource.parsePawScanDraft(_reply(reply));

        expect(draft.observations, isEmpty);
        expect(draft.attentionLevel, PawAttentionLevel.monitor);
      });
    });

    test('runs the safety filter over model output', () {
      // The filter has its own suite; this asserts the parser actually calls
      // it, so a diagnosis in the model's reply can never reach the UI.
      final draft = FlutterFireAiLogicDataSource.parsePawScanDraft(
        _reply(
          _validReply(
            attentionLevel: 'nothingNotable',
            summary: 'Probably a bacterial infection.',
            observations: [
              {'area': 'pad', 'text': 'This looks like an infection.'},
            ],
          ),
        ),
      );

      expect(
        draft.observations.single.text,
        PawScanSafetyFilter.neutralObservation,
      );
      expect(draft.summary, PawScanSafetyFilter.neutralSummary);
      expect(draft.safetyFilterApplied, isTrue);
      expect(draft.attentionLevel, PawScanSafetyFilter.escalatedTo);
    });
  });

  group('PawScanDraft.blocked', () {
    test('carries no verdict and cannot be logged', () {
      const draft = PawScanDraft.blocked();

      expect(draft.status, PawScanDraftStatus.blocked);
      expect(draft.attentionLevel, PawAttentionLevel.undetermined);
      expect(draft.observations, isEmpty);
      expect(draft.isUsable, isFalse);
      expect(draft.canBeLogged, isFalse);
      expect(draft.requiresConfirmation, isTrue);
    });
  });
}
