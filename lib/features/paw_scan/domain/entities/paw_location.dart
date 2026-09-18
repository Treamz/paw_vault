/// Which paw a scan is about. Owners often cannot tell in a close-up photo, so
/// [PawLocation.unspecified] is a first-class answer rather than a failure.
enum PawLocation {
  frontLeft,
  frontRight,
  rearLeft,
  rearRight,
  unspecified,
}
