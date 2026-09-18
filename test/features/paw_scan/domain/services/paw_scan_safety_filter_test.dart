import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_attention_level.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_observation.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_scan_draft.dart';
import 'package:paw_vault/features/paw_scan/domain/services/paw_scan_safety_filter.dart';

PawScanDraft _draft({
  List<String> observations = const [],
  String? summary,
  PawAttentionLevel attentionLevel = PawAttentionLevel.monitor,
  double? confidence = 0.9,
}) {
  return PawScanDraft(
    observations: [
      for (final text in observations)
        PawObservation(area: PawObservationArea.pad, text: text),
    ],
    summary: summary,
    attentionLevel: attentionLevel,
    confidence: confidence,
  );
}

void main() {
  group('breaches', () {
    test('accepts purely visual descriptions', () {
      // These are the observations the feature exists to produce. If the
      // filter ever rejects them there is nothing left to show the owner.
      const allowed = [
        'A dark area near the centre of the main pad.',
        'The pad looks drier and rougher than the surrounding skin.',
        'Redness between the third and fourth toes.',
        'The area appears swollen compared with the other toes.',
        'The nail on the third digit is longer than the others.',
        'Fur between the toes looks matted and damp.',
        'A small cut is visible on the edge of the pad.',
        'Worth showing to a veterinarian.',
      ];

      for (final text in allowed) {
        expect(
          PawScanSafetyFilter.breaches(text),
          isFalse,
          reason: 'should be allowed: $text',
        );
      }
    });

    test('rejects named conditions', () {
      const blocked = [
        'This looks like an infection.',
        'The pad appears infected.',
        'There is an abscess between the toes.',
        'Possibly a tumour on the pad.',
        'This could be cancer.',
        'The toe looks fractured.',
        'A broken nail on the third digit.',
        'Signs of mange.',
        'Likely mites.',
        'This is ringworm.',
        'A fungal growth is visible.',
        'A bacterial issue on the pad.',
        'There are parasites present.',
        'An interdigital cyst.',
        'An ulcer on the pad.',
        'Consistent with arthritis.',
        'This is pododermatitis.',
        'Hyperkeratosis of the pad.',
        'An allergic reaction.',
        'Tissue necrosis is present.',
        'Multiple lesions on the pad.',
      ];

      for (final text in blocked) {
        expect(
          PawScanSafetyFilter.breaches(text),
          isTrue,
          reason: 'should be blocked: $text',
        );
      }
    });

    test('rejects diagnostic and causal framing', () {
      const blocked = [
        'The diagnosis is unclear.',
        'This is consistent with an old injury.',
        'Indicative of trauma.',
        'The redness is caused by licking.',
        'The swelling is due to pressure.',
        'These are symptoms of something systemic.',
        'A sign of a deeper problem.',
        'The pet is suffering from something painful.',
        'This appears benign.',
        'A chronic issue.',
      ];

      for (final text in blocked) {
        expect(
          PawScanSafetyFilter.breaches(text),
          isTrue,
          reason: 'should be blocked: $text',
        );
      }
    });

    test('rejects treatment and medication advice', () {
      const blocked = [
        'Your vet may prescribe something.',
        'Antibiotics would help.',
        'Give an anti-inflammatory.',
        'Apply an ointment twice a day.',
        'A soothing cream will help.',
        'This needs treatment.',
        'It should be treated at home.',
        'Try an epsom salt soak.',
        'Soaking the paw will help.',
        'Bandage the paw.',
        'Surgery may be needed.',
        'A 50 mg dose is typical.',
        'Apply pressure to the area.',
        'Administer the medication daily.',
      ];

      for (final text in blocked) {
        expect(
          PawScanSafetyFilter.breaches(text),
          isTrue,
          reason: 'should be blocked: $text',
        );
      }
    });

    test('treats null and blank text as clean', () {
      expect(PawScanSafetyFilter.breaches(null), isFalse);
      expect(PawScanSafetyFilter.breaches(''), isFalse);
      expect(PawScanSafetyFilter.breaches('   '), isFalse);
    });
  });

  group('apply', () {
    test('passes a clean draft through untouched', () {
      final draft = _draft(
        observations: ['A dark area near the centre of the main pad.'],
        summary: 'One area on the main pad looks different from the rest.',
      );

      final filtered = PawScanSafetyFilter.apply(draft);

      expect(filtered.safetyFilterApplied, isFalse);
      expect(filtered.status, PawScanDraftStatus.awaitingReview);
      expect(filtered.attentionLevel, PawAttentionLevel.monitor);
      expect(
        filtered.observations.single.text,
        'A dark area near the centre of the main pad.',
      );
      expect(
        filtered.summary,
        'One area on the main pad looks different from the rest.',
      );
    });

    test('replaces a breaching observation and flags the draft', () {
      final draft = _draft(observations: ['The pad looks infected.']);

      final filtered = PawScanSafetyFilter.apply(draft);

      expect(
        filtered.observations.single.text,
        PawScanSafetyFilter.neutralObservation,
      );
      expect(filtered.observations.single.text, isNot(contains('infect')));
      expect(filtered.safetyFilterApplied, isTrue);
      expect(filtered.status, PawScanDraftStatus.lowConfidenceReview);
    });

    test('keeps clean observations alongside a replaced one', () {
      final draft = _draft(
        observations: [
          'A dark area near the centre of the main pad.',
          'This looks like an infection.',
        ],
      );

      final filtered = PawScanSafetyFilter.apply(draft);

      expect(
        filtered.observations.first.text,
        'A dark area near the centre of the main pad.',
      );
      expect(
        filtered.observations.last.text,
        PawScanSafetyFilter.neutralObservation,
      );
    });

    test('preserves the area of a replaced observation', () {
      final draft = PawScanDraft(
        observations: const [
          PawObservation(
            area: PawObservationArea.betweenToes,
            text: 'An abscess between the toes.',
          ),
        ],
        attentionLevel: PawAttentionLevel.monitor,
      );

      final filtered = PawScanSafetyFilter.apply(draft);

      expect(filtered.observations.single.area, PawObservationArea.betweenToes);
    });

    test('replaces a breaching summary', () {
      final draft = _draft(summary: 'Probably a bacterial infection.');

      final filtered = PawScanSafetyFilter.apply(draft);

      expect(filtered.summary, PawScanSafetyFilter.neutralSummary);
      expect(filtered.safetyFilterApplied, isTrue);
    });

    test('raises the attention level when it fires', () {
      for (final level in [
        PawAttentionLevel.undetermined,
        PawAttentionLevel.nothingNotable,
        PawAttentionLevel.monitor,
      ]) {
        final filtered = PawScanSafetyFilter.apply(
          _draft(
            observations: ['This looks like an infection.'],
            attentionLevel: level,
          ),
        );

        expect(
          filtered.attentionLevel,
          PawScanSafetyFilter.escalatedTo,
          reason: '$level should escalate',
        );
      }
    });

    test('never lowers an attention level', () {
      // The core safety invariant: suppressing the model's wording must not
      // suppress its signal, or the filter becomes false reassurance.
      final filtered = PawScanSafetyFilter.apply(
        _draft(
          observations: ['This looks like a severe infection.'],
          attentionLevel: PawAttentionLevel.vetPromptly,
        ),
      );

      expect(filtered.attentionLevel, PawAttentionLevel.vetPromptly);
    });

    test('still yields a usable, actionable result when everything is scrubbed',
        () {
      final draft = _draft(
        observations: [
          'An infection on the pad.',
          'Apply an antibiotic ointment.',
        ],
        summary: 'Likely a bacterial infection caused by licking.',
      );

      final filtered = PawScanSafetyFilter.apply(draft);

      expect(filtered.isUsable, isTrue);
      expect(filtered.hasObservations, isTrue);
      expect(filtered.attentionLevel.suggestsVet, isTrue);
      expect(
        filtered.observations.map((o) => o.text),
        everyElement(PawScanSafetyFilter.neutralObservation),
      );
      expect(filtered.summary, PawScanSafetyFilter.neutralSummary);
    });

    test('leaves an unusable draft alone', () {
      const draft = PawScanDraft.unusable(
        photoQuality: PawScanPhotoQuality.notAPaw,
      );

      final filtered = PawScanSafetyFilter.apply(draft);

      expect(filtered.status, PawScanDraftStatus.unusablePhoto);
      expect(filtered.attentionLevel, PawAttentionLevel.undetermined);
      expect(filtered.safetyFilterApplied, isFalse);
      expect(filtered.observations, isEmpty);
    });
  });

  group('PawAttentionLevelSeverity', () {
    test('orders levels with undetermined below every established level', () {
      expect(
        PawAttentionLevel.undetermined.severity,
        lessThan(PawAttentionLevel.nothingNotable.severity),
      );
      expect(
        PawAttentionLevel.nothingNotable.severity,
        lessThan(PawAttentionLevel.monitor.severity),
      );
      expect(
        PawAttentionLevel.monitor.severity,
        lessThan(PawAttentionLevel.vetSoon.severity),
      );
      expect(
        PawAttentionLevel.vetSoon.severity,
        lessThan(PawAttentionLevel.vetPromptly.severity),
      );
    });

    test('raisedTo picks the more serious level in either direction', () {
      expect(
        PawAttentionLevel.monitor.raisedTo(PawAttentionLevel.vetPromptly),
        PawAttentionLevel.vetPromptly,
      );
      expect(
        PawAttentionLevel.vetPromptly.raisedTo(PawAttentionLevel.monitor),
        PawAttentionLevel.vetPromptly,
      );
      expect(
        PawAttentionLevel.undetermined.raisedTo(PawAttentionLevel.monitor),
        PawAttentionLevel.monitor,
      );
    });

    test('suggestsVet only for the two vet levels', () {
      expect(PawAttentionLevel.vetSoon.suggestsVet, isTrue);
      expect(PawAttentionLevel.vetPromptly.suggestsVet, isTrue);
      expect(PawAttentionLevel.monitor.suggestsVet, isFalse);
      expect(PawAttentionLevel.nothingNotable.suggestsVet, isFalse);
      expect(PawAttentionLevel.undetermined.suggestsVet, isFalse);
    });
  });
}
