import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/tmdb_config.dart';
import '../models/movie.dart';
import 'tmdb_mapper.dart';

class TmdbApiException implements Exception {
  TmdbApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'TmdbApiException($statusCode): $message';
}

class TmdbClient {
  TmdbClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('${TmdbConfig.apiBase}$path').replace(
      queryParameters: {
        'api_key': TmdbConfig.apiKey,
        ...?query,
      },
    );
  }

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String>? query,
  ]) async {
    if (!TmdbConfig.hasApiKey) {
      throw TmdbApiException('TMDB API key is missing');
    }

    final response = await _http.get(_uri(path, query));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TmdbApiException(
        'Request failed for $path',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw TmdbApiException('Unexpected response for $path');
    }
    return decoded;
  }

  Future<List<Movie>> _titleList(
    String path, {
    Map<String, String>? query,
    MediaType mediaType = MediaType.movie,
  }) async {
    final json = await _get(path, query);
    final results = (json['results'] as List?) ?? const [];
    return results
        .map(
          (item) => movieFromTmdbJson(
            item as Map<String, dynamic>,
            mediaType: mediaType,
          ),
        )
        .where((title) => title.posterUrl.isNotEmpty)
        .toList();
  }

  Future<List<Movie>> trendingMovies() =>
      _titleList('/trending/movie/week');

  Future<List<Movie>> popularMovies() => _titleList('/movie/popular');

  Future<List<Movie>> nowPlayingMovies() => _titleList('/movie/now_playing');

  Future<List<Movie>> upcomingMovies() => _titleList('/movie/upcoming');

  Future<List<Movie>> topRatedMovies() => _titleList('/movie/top_rated');

  Future<List<Movie>> trendingTv() =>
      _titleList('/trending/tv/week', mediaType: MediaType.tv);

  Future<List<Movie>> popularTv() =>
      _titleList('/tv/popular', mediaType: MediaType.tv);

  Future<List<Movie>> topRatedTv() =>
      _titleList('/tv/top_rated', mediaType: MediaType.tv);

  Future<List<Movie>> onTheAirTv() =>
      _titleList('/tv/on_the_air', mediaType: MediaType.tv);

  Future<List<Movie>> searchMovies(String query) => _titleList(
        '/search/movie',
        query: {'query': query, 'include_adult': 'false'},
      );

  Future<List<Movie>> searchTv(String query) => _titleList(
        '/search/tv',
        query: {'query': query, 'include_adult': 'false'},
        mediaType: MediaType.tv,
      );

  Future<List<Movie>> moviesByGenre(int genreId) => _titleList(
        '/discover/movie',
        query: {
          'with_genres': '$genreId',
          'sort_by': 'popularity.desc',
        },
      );

  Future<MovieDetailsData> movieDetails(
    String id, {
    String preferredRegion = 'US',
  }) async {
    final results = await Future.wait([
      _get('/movie/$id'),
      _get('/movie/$id/credits'),
      _get('/movie/$id/reviews'),
      _get('/movie/$id/similar'),
      _get('/movie/$id/videos'),
      _get('/movie/$id/watch/providers'),
    ]);
    return detailsFromTmdb(
      detail: results[0],
      credits: results[1],
      reviews: results[2],
      similar: results[3],
      videos: results[4],
      watchProviders: results[5],
      preferredRegion: preferredRegion,
      mediaType: MediaType.movie,
    );
  }

  Future<MovieDetailsData> tvDetails(
    String id, {
    String preferredRegion = 'US',
  }) async {
    final results = await Future.wait([
      _get('/tv/$id'),
      _get('/tv/$id/credits'),
      _get('/tv/$id/reviews'),
      _get('/tv/$id/similar'),
      _get('/tv/$id/videos'),
      _get('/tv/$id/watch/providers'),
    ]);
    return detailsFromTmdb(
      detail: results[0],
      credits: results[1],
      reviews: results[2],
      similar: results[3],
      videos: results[4],
      watchProviders: results[5],
      preferredRegion: preferredRegion,
      mediaType: MediaType.tv,
    );
  }

  void close() => _http.close();
}
