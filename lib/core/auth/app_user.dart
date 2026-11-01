/// Store roles, from most to least privileged.
enum UserRole {
  owner('Business Owner'),
  manager('Store Manager'),
  cashier('Cash Counter');

  const UserRole(this.label);
  final String label;

  static UserRole parse(String? raw) =>
      UserRole.values.firstWhere((r) => r.name == raw, orElse: () => UserRole.cashier);
}

/// What each role may open. Routes not listed here are open to everyone
/// who is signed in.
abstract final class Permissions {
  static const _cashierRoutes = {'/sales', '/sales-return', '/inventory', '/settings'};

  static bool canOpen(UserRole role, String route) {
    switch (role) {
      case UserRole.owner:
      case UserRole.manager:
        return true;
      case UserRole.cashier:
        return _cashierRoutes.contains(route);
    }
  }

  static String homeRoute(UserRole role) => role == UserRole.cashier ? '/sales' : '/dashboard';

  /// Adding/removing users, resetting passwords, restoring backups.
  static bool canManageUsers(UserRole role) => role == UserRole.owner;
  static bool canRestoreBackup(UserRole role) => role == UserRole.owner;
  static bool canBackup(UserRole role) => role != UserRole.cashier;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    this.mustChangePassword = false,
  });

  final String id;
  final String username;
  final String displayName;
  final UserRole role;
  final bool mustChangePassword;

  String get roleLabel => role.label;

  bool canOpen(String route) => Permissions.canOpen(role, route);

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return username.substring(0, username.length.clamp(0, 2)).toUpperCase();
    if (parts.length == 1) return parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  AppUser copyWith({bool? mustChangePassword, String? displayName}) => AppUser(
        id: id,
        username: username,
        displayName: displayName ?? this.displayName,
        role: role,
        mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      );
}
