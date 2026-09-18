/// The part of the paw an observation is about.
enum PawObservationArea {
  pad,
  nail,
  betweenToes,
  skin,
  fur,
  overall,
}

/// A single visual observation about a photographed paw.
///
/// [text] is descriptive only — what is visible, never what it means. Model
/// output reaches this class solely through `PawScanSafetyFilter`, which
/// rewrites anything that names a condition or suggests treatment.
class PawObservation {
  const PawObservation({required this.area, required this.text});

  final PawObservationArea area;
  final String text;

  PawObservation copyWith({PawObservationArea? area, String? text}) {
    return PawObservation(area: area ?? this.area, text: text ?? this.text);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PawObservation &&
            runtimeType == other.runtimeType &&
            area == other.area &&
            text == other.text;
  }

  @override
  int get hashCode => Object.hash(area, text);

  @override
  String toString() => 'PawObservation($area, $text)';
}
