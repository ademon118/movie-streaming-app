import 'package:flutter/material.dart';

import 'data/movie_repository.dart';
import 'screens/main_shell.dart';
import 'state/favorites_controller.dart';
import 'state/favorites_scope.dart';
import 'state/movie_repository_scope.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(MovieApp(repository: TmdbMovieRepository()));
}

class MovieApp extends StatefulWidget {
  const MovieApp({
    super.key,
    required this.repository,
  });

  final MovieRepository repository;

  @override
  State<MovieApp> createState() => _MovieAppState();
}

class _MovieAppState extends State<MovieApp> {
  final _favorites = FavoritesController();

  @override
  void dispose() {
    _favorites.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FavoritesScope(
      controller: _favorites,
      child: MovieRepositoryScope(
        repository: widget.repository,
        child: MaterialApp(
          title: 'KyiKyaMal',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkCinema,
          home: const MainShell(),
        ),
      ),
    );
  }
}
