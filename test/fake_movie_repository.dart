import 'package:movie_app/data/movie_repository.dart';
import 'package:movie_app/models/movie.dart';

/// In-memory repository used only by widget tests.
class FakeMovieRepository implements MovieRepository {
  FakeMovieRepository({
    HomeFeed? homeFeed,
    List<Movie>? searchResults,
    List<Movie>? tvSearchResults,
    MovieDetailsData? details,
  })  : _homeFeed = homeFeed ??
            const HomeFeed(
              featured: [_sample],
              trending: [_sample],
              popular: [_sample],
              nowPlaying: [_sample],
              upcoming: [_sample],
              topRated: [_sample],
              tvTrending: [_tvSample],
              tvPopular: [_tvSample],
              tvTopRated: [_tvSample],
              tvOnTheAir: [_tvSample],
            ),
        _searchResults = searchResults ?? const [_sample],
        _tvSearchResults = tvSearchResults ?? const [_tvSample],
        _details = details ??
            MovieDetailsData(
              movie: _sample,
              runtimeMinutes: 120,
              overview: 'Test overview',
              cast: const [CreditPerson(name: 'A', role: 'Lead')],
              crew: const [CreditPerson(name: 'B', role: 'Director')],
              reviews: const [],
              similar: const [],
              watchProviders: const WatchProviderGroup(
                region: 'US',
                flatrate: [
                  WatchProvider(
                    id: 8,
                    name: 'Netflix',
                    logoUrl: '',
                    displayPriority: 1,
                  ),
                ],
              ),
            );

  final HomeFeed _homeFeed;
  final List<Movie> _searchResults;
  final List<Movie> _tvSearchResults;
  final MovieDetailsData _details;

  static const _sample = Movie(
    id: '1',
    title: 'Test Movie',
    posterUrl: '',
    rating: 8.0,
    year: 2024,
    genre: 'Action',
  );

  static const _tvSample = Movie(
    id: '2',
    title: 'Test TV Show',
    posterUrl: '',
    rating: 9.0,
    year: 2023,
    genre: 'Drama',
    mediaType: MediaType.tv,
  );

  @override
  bool get hasTmdbKey => true;

  @override
  Future<HomeFeed> loadHomeFeed() async => _homeFeed;

  @override
  Future<List<Movie>> searchMovies(String query) async {
    if (query.trim().isEmpty) return const [];
    return _searchResults
        .where((m) => m.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<List<Movie>> searchTvShows(String query) async {
    if (query.trim().isEmpty) return const [];
    return _tvSearchResults
        .where((m) => m.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<List<Movie>> moviesForGenreName(String genre) async {
    return _searchResults.where((m) => m.genre == genre).toList();
  }

  @override
  Future<MovieDetailsData> movieDetails(Movie movie) async => _details;
}
