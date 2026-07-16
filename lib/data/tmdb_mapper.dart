import '../config/tmdb_config.dart';
import '../models/movie.dart';

/// Common TMDB genre id → name map (movies + TV).
const tmdbGenreNames = <int, String>{
  28: 'Action',
  12: 'Adventure',
  16: 'Animation',
  35: 'Comedy',
  80: 'Crime',
  99: 'Documentary',
  18: 'Drama',
  10751: 'Family',
  14: 'Fantasy',
  36: 'History',
  27: 'Horror',
  10402: 'Music',
  9648: 'Mystery',
  10749: 'Romance',
  878: 'Sci-Fi',
  10770: 'TV Movie',
  53: 'Thriller',
  10752: 'War',
  37: 'Western',
  10759: 'Action & Adventure',
  10762: 'Kids',
  10763: 'News',
  10764: 'Reality',
  10765: 'Sci-Fi & Fantasy',
  10766: 'Soap',
  10767: 'Talk',
  10768: 'War & Politics',
};

const tmdbTvGenreNames = tmdbGenreNames;

String imageUrl(String? path, {String size = 'w342'}) {
  if (path == null || path.isEmpty) return '';
  return '${TmdbConfig.imageBase}/$size$path';
}

int _yearFromDate(String? date) {
  if (date == null || date.length < 4) return 0;
  return int.tryParse(date.substring(0, 4)) ?? 0;
}

String _primaryGenre(
  List<dynamic>? genreIds,
  List<dynamic>? genres, {
  required MediaType mediaType,
}) {
  if (genres != null && genres.isNotEmpty) {
    final name = genres.first['name'];
    if (name is String && name.isNotEmpty) return name;
  }
  if (genreIds != null && genreIds.isNotEmpty) {
    final id = genreIds.first;
    if (id is int) {
      return tmdbGenreNames[id] ?? (mediaType == MediaType.tv ? 'TV' : 'Movie');
    }
  }
  return mediaType == MediaType.tv ? 'TV' : 'Movie';
}

Movie movieFromTmdbJson(
  Map<String, dynamic> json, {
  MediaType mediaType = MediaType.movie,
}) {
  final genreIds = (json['genre_ids'] as List?)
          ?.whereType<num>()
          .map((e) => e.toInt())
          .toList() ??
      (json['genres'] as List?)
          ?.map((g) => (g as Map)['id'])
          .whereType<num>()
          .map((e) => e.toInt())
          .toList() ??
      const <int>[];

  final genres = json['genres'] as List?;

  return Movie(
    id: '${json['id']}',
    title: (json['title'] as String?)?.trim().isNotEmpty == true
        ? json['title'] as String
        : (json['name'] as String? ?? 'Untitled'),
    posterUrl: imageUrl(json['poster_path'] as String?),
    backdropUrl: imageUrl(json['backdrop_path'] as String?, size: 'w780'),
    rating: (json['vote_average'] as num?)?.toDouble() ?? 0,
    year: _yearFromDate(json['release_date'] as String? ??
        json['first_air_date'] as String?),
    genre: _primaryGenre(genreIds, genres, mediaType: mediaType),
    mediaType: mediaType,
    tagline: (json['tagline'] as String?) ?? '',
    genreIds: genreIds,
  );
}

MovieDetailsData detailsFromTmdb({
  required Map<String, dynamic> detail,
  required Map<String, dynamic> credits,
  required Map<String, dynamic> reviews,
  required Map<String, dynamic> similar,
  Map<String, dynamic>? videos,
  Map<String, dynamic>? watchProviders,
  String preferredRegion = 'US',
  MediaType mediaType = MediaType.movie,
}) {
  final movie = movieFromTmdbJson(detail, mediaType: mediaType);

  final cast = ((credits['cast'] as List?) ?? const [])
      .take(12)
      .map((item) {
        final map = item as Map<String, dynamic>;
        return CreditPerson(
          name: map['name'] as String? ?? 'Unknown',
          role: map['character'] as String? ?? 'Cast',
        );
      })
      .toList();

  final crew = ((credits['crew'] as List?) ?? const [])
      .where((item) {
        final job = (item as Map)['job'] as String? ?? '';
        return job == 'Director' ||
            job == 'Writer' ||
            job == 'Screenplay' ||
            job == 'Producer' ||
            job == 'Director of Photography' ||
            job == 'Creator' ||
            job == 'Executive Producer';
      })
      .take(8)
      .map((item) {
        final map = item as Map<String, dynamic>;
        return CreditPerson(
          name: map['name'] as String? ?? 'Unknown',
          role: map['job'] as String? ?? 'Crew',
        );
      })
      .toList();

  final reviewList = ((reviews['results'] as List?) ?? const [])
      .take(8)
      .map((item) {
        final map = item as Map<String, dynamic>;
        final authorDetails = map['author_details'] as Map<String, dynamic>?;
        return MovieReview(
          author: map['author'] as String? ?? 'User',
          rating: (authorDetails?['rating'] as num?)?.toDouble() ??
              movie.rating,
          body: map['content'] as String? ?? '',
        );
      })
      .where((r) => r.body.trim().isNotEmpty)
      .toList();

  final similarMovies = ((similar['results'] as List?) ?? const [])
      .map(
        (item) => movieFromTmdbJson(
          item as Map<String, dynamic>,
          mediaType: mediaType,
        ),
      )
      .where((m) => m.posterUrl.isNotEmpty)
      .take(12)
      .toList();

  String? trailerKey;
  final videoResults = (videos?['results'] as List?) ?? const [];
  for (final item in videoResults) {
    final map = item as Map<String, dynamic>;
    final site = (map['site'] as String?)?.toLowerCase();
    final type = (map['type'] as String?)?.toLowerCase();
    final key = map['key'] as String?;
    if (site == 'youtube' && key != null && key.isNotEmpty) {
      if (type == 'trailer' || type == 'teaser') {
        trailerKey = key;
        if (type == 'trailer') break;
      }
      trailerKey ??= key;
    }
  }

  return MovieDetailsData(
    movie: movie,
    runtimeMinutes: _runtimeMinutes(detail, mediaType),
    overview: (detail['overview'] as String?)?.trim().isNotEmpty == true
        ? detail['overview'] as String
        : 'No overview available.',
    cast: cast,
    crew: crew,
    reviews: reviewList,
    similar: similarMovies,
    youtubeTrailerKey: trailerKey,
    watchProviders: watchProvidersFromTmdb(
      watchProviders,
      preferredRegion: preferredRegion,
    ),
  );
}

WatchProviderGroup? watchProvidersFromTmdb(
  Map<String, dynamic>? json, {
  required String preferredRegion,
}) {
  if (json == null) return null;
  final results = json['results'];
  if (results is! Map<String, dynamic> || results.isEmpty) return null;

  final preferred = preferredRegion.toUpperCase();

  WatchProviderGroup? forRegion(String regionKey) {
    final region = results[regionKey];
    if (region is! Map<String, dynamic>) return null;
    Uri? link;
    final rawLink = region['link'] as String?;
    if (rawLink != null && rawLink.isNotEmpty) {
      link = Uri.tryParse(rawLink);
    }
    final group = WatchProviderGroup(
      region: regionKey,
      watchPageUrl: link,
      flatrate: _providersList(region['flatrate']),
      rent: _providersList(region['rent']),
      buy: _providersList(region['buy']),
    );
    return group.isEmpty ? null : group;
  }

  return forRegion(preferred) ??
      forRegion('US') ??
      (results.keys.isEmpty ? null : forRegion(results.keys.first));
}

List<WatchProvider> _providersList(dynamic raw) {
  if (raw is! List) return const [];
  final providers = raw
      .whereType<Map>()
      .map((item) {
        final map = Map<String, dynamic>.from(item);
        return WatchProvider(
          id: (map['provider_id'] as num?)?.toInt() ?? 0,
          name: map['provider_name'] as String? ?? 'Unknown',
          logoUrl: imageUrl(map['logo_path'] as String?, size: 'w92'),
          displayPriority: (map['display_priority'] as num?)?.toInt() ?? 999,
        );
      })
      .where((p) => p.name.isNotEmpty)
      .toList()
    ..sort((a, b) => a.displayPriority.compareTo(b.displayPriority));
  return providers;
}

int _runtimeMinutes(Map<String, dynamic> detail, MediaType mediaType) {
  if (mediaType == MediaType.movie) {
    return (detail['runtime'] as num?)?.toInt() ?? 0;
  }
  final runtimes = (detail['episode_run_time'] as List?)
          ?.whereType<num>()
          .map((value) => value.toInt())
          .where((value) => value > 0)
          .toList() ??
      const <int>[];
  if (runtimes.isEmpty) return 0;
  return (runtimes.reduce((a, b) => a + b) / runtimes.length).round();
}
