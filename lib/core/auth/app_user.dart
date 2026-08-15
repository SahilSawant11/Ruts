class AppUser {
  const AppUser({
    required this.username,
    required this.displayName,
    required this.roleLabel,
  });

  final String username;
  final String displayName;
  final String roleLabel;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return username.substring(0, username.length.clamp(0, 2)).toUpperCase();
    if (parts.length == 1) return parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'displayName': displayName,
        'roleLabel': roleLabel,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      username: json['username'] as String,
      displayName: json['displayName'] as String,
      roleLabel: json['roleLabel'] as String,
    );
  }
}
