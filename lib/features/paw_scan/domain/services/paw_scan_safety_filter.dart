import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:paw_vault/features/paw_scan/domain/entities/paw_attention_level.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_observation.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_scan_draft.dart';

/// Last line of defence between the model and the owner.
///
/// Paw Scan is not allowed to diagnose or to recommend treatment. The prompt
/// and the response schema say so, but a prompt is not a guarantee — so every
/// draft passes through this filter before it can be shown.
///
/// Two rules make it safe:
///
/// 1. Any observation that names a condition, asserts a cause, or suggests
///    treatment is **replaced** with neutral wording. The owner never reads
///    the offending sentence.
/// 2. The attention level may only ever be **raised**. If the model reached
///    for a diagnosis it saw something it considered notable, so suppressing
///    the words must not suppress the signal — that would turn a safety
///    measure into false reassurance, the exact failure this feature must
///    avoid.
abstract final class PawScanSafetyFilter {
  /// Shown in place of an observation that breached the rules.
  static const neutralObservation =
      'Something here is worth showing to a veterinarian.';

  /// Shown in place of a summary that breached the rules.
  static const neutralSummary =
      'Something in this photo is worth showing to a veterinarian.';

  /// The lowest attention level a breach may result in. A model that names a
  /// condition has seen something; "keep an eye on it" would understate it.
  static const escalatedTo = PawAttentionLevel.vetSoon;

  /// Case-insensitive pattern helper — every lexicon entry uses it.
  static RegExp _ci(String pattern) => RegExp(pattern, caseSensitive: false);

  /// Named conditions, diagnoses, and pathology. Visual descriptions
  /// ("red", "swollen", "a dark area") are deliberately **not** listed —
  /// describing what is visible is the whole point of the feature. What is
  /// forbidden is naming what it *is*.
  @visibleForTesting
  static final conditionPatterns = <RegExp>[
    _ci(r'\binfect(?:ion|ions|ed|ious)\b'),
    _ci(r'\babscess(?:es|ed)?\b'),
    _ci(r'\btumou?rs?\b'),
    _ci(r'\bcancer(?:ous)?\b|\bcarcinoma\b|\bmelanoma\b|\bsarcoma\b'),
    _ci(r'\bfractur(?:e|es|ed)\b|\bbroken\s+(?:bone|toe|nail|claw)\b'),
    _ci(r'\bsprain(?:ed|s)?\b|\bdislocat(?:ed|ion)\b'),
    _ci(r'\bmange\b|\bmites?\b|\bringworm\b|\bfleas?\b|\bticks?\b'),
    _ci(r'\bfung(?:us|al|i)\b|\byeast\b|\bbacteri(?:a|al)\b'),
    _ci(r'\bparasit(?:e|es|ic)\b'),
    _ci(r'\bcysts?\b|\bulcers?\b|\bulcerat(?:ed|ion)\b'),
    _ci(r'\barthritis\b|\bdysplasia\b'),
    _ci(r'\b\w*dermatitis\b|\bpyoderma\b|\bhyperkeratosis\b'),
    _ci(r'\ballerg(?:y|ies|ic)\b'),
    _ci(r'\bnecro(?:sis|tic)\b|\bgangrene\b|\bsepsis\b'),
    _ci(r'\blesions?\b|\bgranuloma\b'),
  ];

  /// Language that asserts a cause or a conclusion rather than describing.
  @visibleForTesting
  static final diagnosticPatterns = <RegExp>[
    _ci(r'\bdiagnos(?:is|e|ed|es|tic)\b'),
    _ci(r'\bconsistent\s+with\b|\bindicative\s+of\b'),
    _ci(r'\bcaused\s+by\b|\bdue\s+to\b|\bresult\s+of\b'),
    _ci(r'\b(?:symptom|sign|indication)s?\s+of\b'),
    _ci(r'\bsuffering\s+from\b|\bhas\s+developed\b'),
    _ci(r'\bbenign\b|\bmalignant\b|\bchronic\b|\bacute\b'),
  ];

  /// Treatment, medication, and home-remedy language.
  @visibleForTesting
  static final treatmentPatterns = <RegExp>[
    _ci(r'\bprescrib(?:e|ed|ing|es)\b|\bprescriptions?\b'),
    _ci(r'\bantibiotics?\b|\bantifungals?\b|\bantiseptics?\b'),
    _ci(r'\bmedicat(?:e|ed|ion|ions)\b|\bpainkillers?\b'),
    _ci(r'\banti-?inflammator(?:y|ies)\b|\bsteroids?\b'),
    _ci(r'\bointments?\b|\bcreams?\b|\bbalms?\b|\bsalves?\b'),
    _ci(r'\btreatments?\b|\btreated\b|\btreating\b'
        r'|\btreat\s+(?:it|this|them|the)\b'),
    _ci(r'\bremed(?:y|ies)\b|\bepsom\b|\bsoak(?:ing|s)?\b'),
    _ci(r'\bbandag(?:e|es|ing)\b|\bsurg(?:ery|ical)\b'),
    _ci(r'\bdos(?:e|es|age)\b|\bmilligrams?\b|\bmg\b'),
    _ci(r'\bapply\b|\badminister\b'),
  ];

  static Iterable<RegExp> get _allPatterns => [
        ...conditionPatterns,
        ...diagnosticPatterns,
        ...treatmentPatterns,
      ];

  /// Whether [text] breaches the non-diagnostic rules.
  @visibleForTesting
  static bool breaches(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    return _allPatterns.any((pattern) => pattern.hasMatch(text));
  }

  /// Rewrites [draft] so nothing diagnostic reaches the owner.
  ///
  /// An unusable photo is returned untouched: it carries no observations and no
  /// attention level, so there is nothing to scrub and nothing to escalate.
  static PawScanDraft apply(PawScanDraft draft) {
    if (!draft.isUsable) return draft;

    var breached = false;

    final observations = <PawObservation>[
      for (final observation in draft.observations)
        if (breaches(observation.text))
          (() {
            breached = true;
            return observation.copyWith(text: neutralObservation);
          })()
        else
          observation,
    ];

    var summary = draft.summary;
    if (breaches(summary)) {
      breached = true;
      summary = neutralSummary;
    }

    if (!breached) {
      return draft.copyWith(observations: observations, summary: summary);
    }

    return draft.copyWith(
      observations: observations,
      summary: summary,
      attentionLevel: draft.attentionLevel.raisedTo(escalatedTo),
      status: PawScanDraftStatus.lowConfidenceReview,
      safetyFilterApplied: true,
    );
  }
}
