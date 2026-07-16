enum MediaType { movie, tv }

class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.rating,
    required this.year,
    required this.genre,
    this.mediaType = MediaType.movie,
    this.tagline = '',
    this.backdropUrl,
    this.genreIds = const [],
  });

  final String id;
  final String title;
  final String posterUrl;
  final double rating;
  final int year;
  final String genre;
  final MediaType mediaType;
  final String tagline;
  final String? backdropUrl;
  final List<int> genreIds;

  bool get isTv => mediaType == MediaType.tv;

  String get imageUrl => backdropUrl ?? posterUrl;

  String get favoriteKey => '${mediaType.name}:$id';

  Movie copyWith({
    String? id,
    String? title,
    String? posterUrl,
    double? rating,
    int? year,
    String? genre,
    MediaType? mediaType,
    String? tagline,
    String? backdropUrl,
    List<int>? genreIds,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      posterUrl: posterUrl ?? this.posterUrl,
      rating: rating ?? this.rating,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      mediaType: mediaType ?? this.mediaType,
      tagline: tagline ?? this.tagline,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      genreIds: genreIds ?? this.genreIds,
    );
  }
}

class CreditPerson {
  const CreditPerson({
    required this.name,
    required this.role,
  });

  final String name;
  final String role;
}

class MovieReview {
  const MovieReview({
    required this.author,
    required this.rating,
    required this.body,
  });

  final String author;
  final double rating;
  final String body;
}

class MovieDetailsData {
  const MovieDetailsData({
    required this.movie,
    required this.runtimeMinutes,
    required this.overview,
    required this.cast,
    required this.crew,
    required this.reviews,
    required this.similar,
    this.youtubeTrailerKey,
    this.watchProviders,
  });

  final Movie movie;
  final int runtimeMinutes;
  final String overview;
  final List<CreditPerson> cast;
  final List<CreditPerson> crew;
  final List<MovieReview> reviews;
  final List<Movie> similar;
  final String? youtubeTrailerKey;
  final WatchProviderGroup? watchProviders;
}

class WatchProvider {
  const WatchProvider({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.displayPriority,
  });

  final int id;
  final String name;
  final String logoUrl;
  final int displayPriority;
}

class WatchProviderGroup {
  const WatchProviderGroup({
    required this.region,
    this.watchPageUrl,
    this.flatrate = const [],
    this.rent = const [],
    this.buy = const [],
  });

  final String region;
  final Uri? watchPageUrl;
  final List<WatchProvider> flatrate;
  final List<WatchProvider> rent;
  final List<WatchProvider> buy;

  bool get isEmpty =>
      flatrate.isEmpty && rent.isEmpty && buy.isEmpty;

  bool get isNotEmpty => !isEmpty;
}

class HomeFeed {
  const HomeFeed({
    required this.featured,
    required this.trending,
    required this.popular,
    required this.nowPlaying,
    required this.upcoming,
    required this.topRated,
    required this.tvTrending,
    required this.tvPopular,
    required this.tvTopRated,
    required this.tvOnTheAir,
  });

  final List<Movie> featured;
  final List<Movie> trending;
  final List<Movie> popular;
  final List<Movie> nowPlaying;
  final List<Movie> upcoming;
  final List<Movie> topRated;
  final List<Movie> tvTrending;
  final List<Movie> tvPopular;
  final List<Movie> tvTopRated;
  final List<Movie> tvOnTheAir;
}
