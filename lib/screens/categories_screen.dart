import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../models/movie.dart';
import '../state/movie_repository_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_poster_grid.dart';
import '../widgets/skeletons/app_skeletons.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static const _genreIcons = <String, IconData>{
    'Action': Icons.local_fire_department_outlined,
    'Adventure': Icons.explore_outlined,
    'Animation': Icons.brush_outlined,
    'Comedy': Icons.sentiment_satisfied_alt_outlined,
    'Crime': Icons.gavel_outlined,
    'Drama': Icons.theater_comedy_outlined,
    'Fantasy': Icons.auto_awesome_outlined,
    'Horror': Icons.nightlight_outlined,
    'Romance': Icons.favorite_border_rounded,
    'Sci-Fi': Icons.rocket_launch_outlined,
    'Thriller': Icons.psychology_outlined,
    'Mystery': Icons.search_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Categories',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.55,
                ),
                itemCount: movieGenres.length,
                itemBuilder: (context, index) {
                  final genre = movieGenres[index];
                  return Material(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => GenreMoviesScreen(genre: genre),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _genreIcons[genre] ?? Icons.movie_outlined,
                              color: AppTheme.accent,
                              size: 28,
                            ),
                            const Spacer(),
                            Text(
                              genre,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Browse',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GenreMoviesScreen extends StatefulWidget {
  const GenreMoviesScreen({super.key, required this.genre});

  final String genre;

  @override
  State<GenreMoviesScreen> createState() => _GenreMoviesScreenState();
}

class _GenreMoviesScreenState extends State<GenreMoviesScreen> {
  late Future<List<Movie>> _future;
  var _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    _future =
        MovieRepositoryScope.of(context).moviesForGenreName(widget.genre);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.genre)),
      body: FutureBuilder<List<Movie>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const PosterGridSkeleton();
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Could not load ${widget.genre} movies',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            );
          }

          final movies = snapshot.data ?? const <Movie>[];
          if (movies.isEmpty) {
            return Center(
              child: Text(
                'No movies in ${widget.genre} yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            );
          }

          return MoviePosterGrid(movies: movies);
        },
      ),
    );
  }
}
