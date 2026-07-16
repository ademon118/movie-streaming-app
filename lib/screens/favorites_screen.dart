import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../navigation/movie_navigation.dart';
import '../state/favorites_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_network_image.dart';

enum FavoriteSort { recentlyAdded, rating, releaseDate }

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  FavoriteSort _sort = FavoriteSort.recentlyAdded;

  List<Movie> _sorted(List<Movie> favorites) {
    final items = List<Movie>.from(favorites);
    switch (_sort) {
      case FavoriteSort.recentlyAdded:
        return items;
      case FavoriteSort.rating:
        items.sort((a, b) => b.rating.compareTo(a.rating));
        return items;
      case FavoriteSort.releaseDate:
        items.sort((a, b) => b.year.compareTo(a.year));
        return items;
    }
  }

  void _remove(Movie movie) {
    final favorites = FavoritesScope.read(context);
    favorites.remove(movie);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed “${movie.title}”'),
        backgroundColor: AppTheme.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppTheme.accent,
          onPressed: () => favorites.add(movie),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = FavoritesScope.of(context);
    final movies = _sorted(favorites.items);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Favorites',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  PopupMenuButton<FavoriteSort>(
                    tooltip: 'Sort',
                    initialValue: _sort,
                    onSelected: (value) => setState(() => _sort = value),
                    color: AppTheme.surfaceElevated,
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: FavoriteSort.recentlyAdded,
                        child: Text('Recently Added'),
                      ),
                      PopupMenuItem(
                        value: FavoriteSort.rating,
                        child: Text('Rating'),
                      ),
                      PopupMenuItem(
                        value: FavoriteSort.releaseDate,
                        child: Text('Release Date'),
                      ),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Icon(Icons.sort_rounded, color: AppTheme.accent),
                          SizedBox(width: 4),
                          Text(
                            'Sort',
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '${movies.length} saved',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Expanded(
              child: movies.isEmpty
                  ? Center(
                      child: Text(
                        'No favorites yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.48,
                      ),
                      itemCount: movies.length,
                      itemBuilder: (context, index) {
                        final movie = movies[index];
                        return _FavoriteTile(
                          movie: movie,
                          onOpen: () => openMovieDetails(context, movie),
                          onRemove: () => _remove(movie),
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

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
    required this.movie,
    required this.onOpen,
    required this.onRemove,
  });

  final Movie movie;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onOpen,
                    borderRadius: BorderRadius.circular(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: MovieNetworkImage(
                        url: movie.posterUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onRemove,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: AppTheme.accent,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onOpen,
          child: Text(
            movie.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        if (movie.rating > 0) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 14, color: AppTheme.accent),
              const SizedBox(width: 2),
              Text(
                movie.rating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
