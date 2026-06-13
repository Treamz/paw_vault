class AppUser {
  const AppUser({
    required this.id,
    required this.isAnonymous,
    this.email,
    this.displayName,
  });

  final String id;
  final bool isAnonymous;
  final String? email;
  final String? displayName;
}
