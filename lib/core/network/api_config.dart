/// Points at your local Xoxo.Api instance (dotnet run --project Xoxo.Api).
///
/// TODO before shipping to a real client machine: this needs to become a
/// runtime-configurable value (e.g. read from a settings screen or
/// --dart-define) instead of a hardcoded dev URL, since "localhost" only
/// means "this PC" — a client's machine won't have your API running.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'http://localhost:5024';

  static Uri uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }
}
