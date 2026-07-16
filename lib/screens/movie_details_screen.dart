import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/movie.dart';
import '../navigation/watch_navigation.dart';
import '../state/favorites_scope.dart';
import '../state/movie_repository_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_section.dart';
import '../widgets/skeletons/app_skeletons.dart';
import '../widgets/movie_network_image.dart';

class MovieDetailsScreen extends StatefulWidget {
  const MovieDetailsScreen({
    super.key,
    required this.movie,
  });

  final Movie movie;

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  late Future<MovieDetailsData> _detailsFuture;
  var _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    _detailsFuture =
        MovieRepositoryScope.of(context).movieDetails(widget.movie);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MovieDetailsData>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MovieDetailsSkeleton(title: widget.movie.title);
        }

        final details = snapshot.data ??
            MovieDetailsData(
              movie: widget.movie,
              runtimeMinutes: 0,
              overview: 'Unable to load details.',
              cast: const [],
              crew: const [],
              reviews: const [],
              similar: const [],
            );

        return _MovieDetailsBody(details: details);
      },
    );
  }
}

class _MovieDetailsBody extends StatelessWidget {
  const _MovieDetailsBody({required this.details});

  final MovieDetailsData details;

  Movie get movie => details.movie;

  @override
  Widget build(BuildContext context) {
    final favorites = FavoritesScope.of(context);
    final isFavorite = favorites.containsMovie(movie);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: AppTheme.scaffoldBackground,
            actions: [
              IconButton(
                tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
                onPressed: () => favorites.toggle(movie),
                icon: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border,
                  color: isFavorite ? AppTheme.accent : AppTheme.textPrimary,
                ),
              ),
              IconButton(
                tooltip: 'Share',
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: '${movie.title} (${movie.year})'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Title copied for sharing'),
                      backgroundColor: AppTheme.surfaceElevated,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.share_rounded),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  MovieNetworkImage(
                    url: movie.imageUrl.isNotEmpty
                        ? movie.imageUrl
                        : movie.posterUrl,
                    fit: BoxFit.cover,
                    iconSize: 64,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          AppTheme.scaffoldBackground.withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: movie.posterUrl.isEmpty
                              ? Container(
                                  width: 96,
                                  height: 144,
                                  color: AppTheme.posterPlaceholder,
                                )
                              : MovieNetworkImage(
                                  url: movie.posterUrl,
                                  width: 96,
                                  height: 144,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                movie.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              if (movie.isTv) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppTheme.accent.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: const Text(
                                    'TV Series',
                                    style: TextStyle(
                                      color: AppTheme.accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                [
                                  if (movie.year > 0) '${movie.year}',
                                  movie.genre,
                                  if (details.runtimeMinutes > 0)
                                    _formatRuntime(details.runtimeMinutes),
                                ].join(' · '),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (movie.rating > 0) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: AppTheme.accent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      movie.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: AppTheme.accent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (movie.tagline.isNotEmpty) ...[
                    Text(
                      movie.tagline,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => openMovieWatch(context, movie),
                          icon: const Icon(Icons.play_circle_fill_rounded),
                          label: const Text('Watch'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: AppTheme.scaffoldBackground,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => openMovieTrailer(
                            context,
                            movie: movie,
                            youtubeKey: details.youtubeTrailerKey,
                          ),
                          icon: const Icon(Icons.ondemand_video_rounded),
                          label: const Text('Trailer'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accent,
                            side: const BorderSide(color: AppTheme.accent),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => favorites.toggle(movie),
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border,
                      ),
                      label: Text(
                        isFavorite ? 'Saved to Favorites' : 'Add to Favorites',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.surfaceElevated),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    details.overview,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Cast',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 118,
              child: details.cast.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      itemCount: details.cast.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final person = details.cast[index];
                        return SizedBox(
                          width: 88,
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: AppTheme.surfaceElevated,
                                child: Text(
                                  person.name.isNotEmpty
                                      ? person.name.characters.first
                                      : '?',
                                  style: const TextStyle(
                                    color: AppTheme.accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                person.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                person.role,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crew',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (details.crew.isEmpty)
                    Text(
                      'No crew info',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    ...details.crew.map(
                      (person) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                person.name,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              person.role,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        'Reviews',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      if (details.reviews.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ReviewsScreen(
                                  movieTitle: movie.title,
                                  reviews: details.reviews,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'See all',
                            style: TextStyle(color: AppTheme.accent),
                          ),
                        ),
                    ],
                  ),
                  if (details.reviews.isEmpty)
                    Text(
                      'No reviews yet',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    ...details.reviews.take(2).map(
                          (review) => _ReviewTile(review: review),
                        ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (details.similar.isNotEmpty)
            SliverToBoxAdapter(
              child: MovieSection(
                title: 'Similar movies',
                movies: details.similar,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }

  String _formatRuntime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) return '${mins}m';
    return '${hours}h ${mins}m';
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final MovieReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                review.author,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              const Icon(Icons.star_rounded, size: 16, color: AppTheme.accent),
              const SizedBox(width: 2),
              Text(
                review.rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            review.body,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({
    super.key,
    required this.movieTitle,
    required this.reviews,
  });

  final String movieTitle;
  final List<MovieReview> reviews;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reviews · $movieTitle')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reviews.length,
        itemBuilder: (context, index) => _ReviewTile(review: reviews[index]),
      ),
    );
  }
}
