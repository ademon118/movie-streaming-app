import 'tmdb_secrets.dart';

/// TMDB API configuration.
///
/// Set your key in either place:
/// 1. `lib/config/tmdb_secrets.dart` → `tmdbApiKeyOverride`
/// 2. Run with:
///    `flutter run --dart-define=TMDB_API_KEY=your_key_here`
class TmdbConfig {
  static const String apiBase = 'https://api.themoviedb.org/3';
  static const String imageBase = 'https://image.tmdb.org/t/p';

  static const String _defineKey = String.fromEnvironment('TMDB_API_KEY');

  static String get apiKey {
    if (_defineKey.isNotEmpty) return _defineKey;
    return tmdbApiKeyOverride;
  }

  static bool get hasApiKey => apiKey.trim().isNotEmpty;
}
