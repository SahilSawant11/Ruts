import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// One shared http.Client for the app's lifetime. Riverpod disposes it
/// automatically if this provider is ever overridden/torn down (e.g. in
/// tests), which is why we hook `ref.onDispose` here.
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});
