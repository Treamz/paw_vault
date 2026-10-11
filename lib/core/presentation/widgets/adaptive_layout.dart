import 'dart:ui';

/// Whether a surface is big enough to show a list and the thing it selects
/// side by side.
///
/// Both tests matter, and each one rules out a case the other lets through:
///
/// * Width alone would turn a phone on its side into a two-pane layout. An
///   iPhone 17 Pro Max in landscape is about 956 by 440, so it clears any
///   sensible width bar while having no height to spend on two panes.
/// * Shortest side alone -- the usual way to tell a tablet from a phone --
///   would accept a folded iPhone Duo, which is 466 across.
///
/// What each device does here:
///
/// | surface            | width | shortest | two panes |
/// |--------------------|-------|----------|-----------|
/// | iPhone portrait    |   440 |      440 | no        |
/// | iPhone landscape   |   956 |      440 | no        |
/// | iPhone Duo folded  |   466 |      466 | no        |
/// | iPhone Duo open    |   951 |      669 | yes       |
/// | iPad 13" portrait  |  1024 |     1024 | yes       |
bool hasRoomForTwoPanes(Size size) =>
    size.width >= _minWidth && size.shortestSide >= _minShortestSide;

const double _minWidth = 900;
const double _minShortestSide = 600;

/// How wide the list is when it sits beside what it selects.
///
/// Shared so the three two-pane screens cannot drift apart. Sized by the
/// densest of them: a document row carries a title, a type and date, a file
/// count and an expiry, and below this it wraps the title onto three lines.
const double twoPaneListWidth = 420;

/// Room under a list that shares its pane with a floating button, which
/// otherwise comes to rest on the last row.
const double twoPaneListBottomInset = 96;
