import 'package:paw_vault/features/paw_scan/domain/entities/paw_attention_level.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_location.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_observation.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_scan_draft.dart';

/// Every word Paw Scan shows the owner lives here.
///
/// Deliberately in the domain layer, not presentation: the same wording has to
/// reach the screen *and* the exported vet summary PDF, which is built in the
/// data layer. Nothing here imports Flutter.
///
/// The wording is the feature's safety boundary as much as the code is, so it
/// is kept in one file that can be read end to end and reviewed on its own.
/// Three rules govern it:
///
/// * Nothing names a condition, a cause, or a treatment.
/// * Nothing reads as reassurance. "Nothing stood out" describes one
///   photograph; it never says the paw is fine, healthy, or normal.
/// * Anything uncertain points at a vet rather than filling the gap.
abstract final class PawScanCopy {
  static const disclaimerTitle = 'Descriptions, not a diagnosis';

  static const disclaimerBody =
      'Paw Scan describes what it can see in your photos and nothing more. It '
      'cannot tell you what something is, it is not a veterinary opinion, and '
      'it is not a substitute for your vet. If you are worried about your '
      'pet, contact your vet.';

  /// Printed in the exported vet summary PDF, where a vet will read it.
  static const vetSummaryDisclaimer =
      'These are AI-generated visual descriptions of photographs supplied by '
      'the owner. They are not a diagnosis and were not produced or reviewed '
      'by a veterinarian. The photographs are available in the PawVault app.';

  static const nothingSavedYet = 'Nothing is saved until you confirm.';

  static const lowConfidenceNotice =
      'The photos were hard to read, so these descriptions may be off. Take '
      'another look in better light, or show your vet.';

  static const safetyFilteredNotice =
      'One description was hidden because it read as a medical opinion rather '
      'than something visible. Show these photos to your vet.';

  static const captureTips =
      'Fill the frame with the paw, use daylight or a bright room, avoid '
      'flash, and hold the paw still. Take one photo per paw you want to '
      'record.';

  static const reportResult = 'Report this result';
}

/// The label for an attention level.
///
/// [PawAttentionLevel.nothingNotable] is phrased about the photograph, not the
/// pet: "nothing stood out in these photos" is something the app can honestly
/// claim, where "healthy" is not.
String formatPawAttentionLevel(PawAttentionLevel level) {
  return switch (level) {
    PawAttentionLevel.nothingNotable => 'Nothing stood out',
    PawAttentionLevel.monitor => 'Keep an eye on it',
    PawAttentionLevel.vetSoon => 'Worth showing a vet soon',
    PawAttentionLevel.vetPromptly => 'Contact a vet promptly',
    PawAttentionLevel.undetermined => 'No result',
  };
}

/// The app-authored sentence under an attention level.
///
/// Written here rather than asked of the model: "what should I do about this"
/// is advice, and advice is the one thing Paw Scan must not generate.
String formatPawAttentionGuidance(PawAttentionLevel level) {
  return switch (level) {
    PawAttentionLevel.nothingNotable =>
      'Nothing in these photos stood out. That is not a clean bill of health '
          '— keep taking checks so you have a record over time.',
    PawAttentionLevel.monitor =>
      'Something small showed up in these photos. Take another check in a few '
          'days and compare them.',
    PawAttentionLevel.vetSoon =>
      'Something in these photos stands out. Consider showing it to your vet '
          'at your next convenient opportunity.',
    PawAttentionLevel.vetPromptly =>
      'Something in these photos stands out clearly. Contact your vet — they '
          'can tell you what it actually is.',
    PawAttentionLevel.undetermined =>
      'Paw Scan could not describe these photos. Try again, and contact your '
          'vet if you are worried about your pet.',
  };
}

String formatPawLocation(PawLocation location) {
  return switch (location) {
    PawLocation.frontLeft => 'Front left',
    PawLocation.frontRight => 'Front right',
    PawLocation.rearLeft => 'Rear left',
    PawLocation.rearRight => 'Rear right',
    PawLocation.unspecified => 'Not sure',
  };
}

String formatPawObservationArea(PawObservationArea area) {
  return switch (area) {
    PawObservationArea.pad => 'Pad',
    PawObservationArea.nail => 'Nail',
    PawObservationArea.betweenToes => 'Between the toes',
    PawObservationArea.skin => 'Skin',
    PawObservationArea.fur => 'Fur',
    PawObservationArea.overall => 'Overall',
  };
}

/// The title shown when a scan was rejected before any verdict.
String formatPawRejectionTitle(PawScanDraft draft) {
  if (draft.status == PawScanDraftStatus.blocked) {
    return 'Could not analyse this photo';
  }

  return switch (draft.photoQuality) {
    PawScanPhotoQuality.notAPaw => 'That does not look like a paw',
    PawScanPhotoQuality.blurry ||
    PawScanPhotoQuality.tooDark ||
    PawScanPhotoQuality.tooFarAway =>
      'Photo too unclear',
    PawScanPhotoQuality.usable => 'Could not read the result',
  };
}

/// The message shown when a scan was rejected.
String formatPawRejectionMessage(PawScanDraft draft) {
  if (draft.status == PawScanDraftStatus.blocked) {
    // The most important string in the feature: the model most often refuses
    // on badly injured paws, which is exactly when waiting is the wrong call.
    return 'If your pet\'s paw is bleeding or badly injured, contact your vet '
        'now. Paw Scan cannot help with this photo.';
  }

  return switch (draft.photoQuality) {
    PawScanPhotoQuality.notAPaw =>
      'Paw Scan only describes photos of a pet\'s paw. Try again with the paw '
          'filling most of the frame.',
    PawScanPhotoQuality.blurry => 'The photo was too blurry to describe. '
        '${PawScanCopy.captureTips}',
    PawScanPhotoQuality.tooDark => 'The photo was too dark to describe. '
        '${PawScanCopy.captureTips}',
    PawScanPhotoQuality.tooFarAway => 'The paw was too far away to describe. '
        '${PawScanCopy.captureTips}',
    PawScanPhotoQuality.usable =>
      'Please try again. If you are worried about your pet, contact your vet.',
  };
}
