/// Global application configuration constants.
///
/// `offlineOnly` is `true` for this release: the POS runs entirely
/// against the local SQLite database.  No server, no sync.
abstract final class AppConfig {
  /// When `true` every repository reads/writes the local Drift DB
  /// exclusively.  Remote API calls, `syncPending*()`, and
  /// connectivity checks are all bypassed.
  static const bool offlineOnly = true;

  /// Shown in the status bar and support screens. Keep in sync with
  /// `version:` in pubspec.yaml (release builds may override it).
  static const String version = String.fromEnvironment('CASKLY_VERSION', defaultValue: '1.0.0');
}
