/// Contact details of the pet owner, editable in the app and stored on the
/// user's own document.
class OwnerProfile {
  const OwnerProfile({this.name, this.phone});

  final String? name;
  final String? phone;

  bool get isEmpty =>
      (name == null || name!.isEmpty) && (phone == null || phone!.isEmpty);
}
