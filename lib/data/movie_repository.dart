import 'dart:ui' show PlatformDispatcher;

import '../config/tmdb_config.dart';
import '../models/movie.dart';
import 'tmdb_client.dart';
import 'tmdb_mapper.dart';

abstract class MovieRepository {
  bool get hasTmdbKey;

  Future<HomeFeed> loadHomeFeed();

  Future<List<Movie>> searchMovies(String query);

  Future<List<Movie>> searchTvShows(String query);

  Future<List<Movie>> moviesForGenreName(String genre);

  Future<MovieDetailsData> movieDetails(Movie movie);
}

class TmdbMovieRepository implements MovieRepository {
  TmdbMovieRepository({TmdbClient? client}) : _client = client ?? TmdbClient();

  final TmdbClient _client;

  @override
  bool get hasTmdbKey => TmdbConfig.hasApiKey;

  /// Device country → uppercase; empty falls back to US.
  static String resolveWatchRegion() {
    final code = PlatformDispatcher.instance.locale.countryCode?.trim();
    if (code == null || code.isEmpty) return 'US';
    return code.toUpperCase();
  }

  @override
  Future<HomeFeed> loadHomeFeed() async {
    _ensureKey();
    final results = await Future.wait([
      _client.trendingMovies(),
      _client.popularMovies(),
      _client.nowPlayingMovies(),
      _client.upcomingMovies(),
      _client.topRatedMovies(),
      _client.trendingTv(),
      _client.popularTv(),
      _client.topRatedTv(),
      _client.onTheAirTv(),
    ]);

    final trending = results[0];
    final tvTrending = results[5];
    return HomeFeed(
      featured: trending.take(5).toList(),
      trending: trending,
      popular: results[1],
      nowPlaying: results[2],
      upcoming: results[3],
      topRated: results[4],
      tvTrending: tvTrending,
      tvPopular: results[6],
      tvTopRated: results[7],
      tvOnTheAir: results[8],
    );
  }

  @override
  Future<List<Movie>> searchMovies(String query) async {
    _ensureKey();
    final q = query.trim();
    if (q.isEmpty) return const [];
    return _client.searchMovies(q);
  }

  @override
  Future<List<Movie>> searchTvShows(String query) async {
    _ensureKey();
    final q = query.trim();
    if (q.isEmpty) return const [];
    return _client.searchTv(q);
  }

  @override
  Future<List<Movie>> moviesForGenreName(String genre) async {
    _ensureKey();
    final entry = tmdbGenreNames.entries.where(
      (e) => e.value.toLowerCase() == genre.toLowerCase(),
    );
    if (entry.isEmpty) return const [];
    return _client.moviesByGenre(entry.first.key);
  }

  @override
  Future<MovieDetailsData> movieDetails(Movie movie) async {
    _ensureKey();
    final region = resolveWatchRegion();
    if (movie.isTv) {
      return _client.tvDetails(movie.id, preferredRegion: region);
    }
    return _client.movieDetails(movie.id, preferredRegion: region);
  }

  void _ensureKey() {
    if (!hasTmdbKey) {
      throw StateError(
        'TMDB API key missing. Set tmdbApiKeyOverride or TMDB_API_KEY.',
      );
    }
  }
}
