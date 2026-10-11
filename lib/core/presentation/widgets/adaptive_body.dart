import 'package:flutter/material.dart';

/// A screen body that stays readable when the window is wide.
///
/// Every screen ran its content to both edges, which is right on a phone and
/// wrong everywhere else. An unfolded iPhone Duo is 951 logical pixels across
/// and the iPad build is wider still; at that width a settings row is an icon
/// on the far left and a chevron most of a screen away, and a text field is a
/// line you have to track across. Centring the content and capping it at a
/// comfortable measure fixes that without any per-screen layout work.
///
/// Below [defaultMaxWidth] this changes nothing at all, so phones are
/// untouched: the widest of them is around 440 logical pixels, so the
/// constraint never binds there and the pixels a phone renders stay identical.
///
/// It also carries the [SafeArea] that every screen needs. Duo is the first
/// device whose status bar is a vertical strip down the right edge, so it is
/// the first device where the horizontal insets are not zero.
class AdaptiveBody extends StatelessWidget {
  const AdaptiveBody({
    required this.child,
    this.maxWidth = defaultMaxWidth,
    super.key,
  });

  /// Wide enough for a form field to stay one comfortable line, narrow enough
  /// that a row's trailing control stays near its label.
  static const double defaultMaxWidth = 700;

  final Widget child;

  /// Override only for a screen whose content genuinely wants more room.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
