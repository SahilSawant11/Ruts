/// Global application configuration constants.
///
/// `offlineOnly` is `true` for this release: the POS runs entirely
/// against the local SQLite database.  No server, no sync.
abstract final class AppConfig {
  /// When `true` every repository reads/writes the local Drift DB
  /// exclusively.  Remote API calls, `syncPending*()`, and
  /// connectivity checks are all bypassed.
  static const bool offlineOnly = true;
}
