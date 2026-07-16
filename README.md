# KyiKyaMal (movie_app)

Flutter movie browsing app — branded as **KyiKyaMal**.

## TMDB API

Live movie data uses [The Movie Database (TMDB)](https://www.themoviedb.org/) API.

1. Create an API key: https://www.themoviedb.org/settings/api
2. Either:
   - Put it in `lib/config/tmdb_secrets.dart`:
     ```dart
     const String tmdbApiKeyOverride = 'YOUR_KEY';
     ```
   - Or run with:
     ```bash
     flutter run --dart-define=TMDB_API_KEY=YOUR_KEY
     ```

Without a key the app cannot load catalogs — set the key before running.

## Run

```bash
flutter pub get
flutter run
```
