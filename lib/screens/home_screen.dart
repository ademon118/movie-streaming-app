import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../state/movie_repository_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/home_hero_banner.dart';
import '../widgets/movie_section.dart';
import '../widgets/skeletons/app_skeletons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onSearchTap,
  });

  final VoidCallback? onSearchTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<HomeFeed> _feedFuture;
  var _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    _feedFuture = MovieRepositoryScope.of(context).loadHomeFeed();
  }

  Future<void> _reload() async {
    setState(() {
      _feedFuture = MovieRepositoryScope.of(context).loadHomeFeed();
    });
    await _feedFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<HomeFeed>(
          future: _feedFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const HomeSkeleton();
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        color: AppTheme.textSecondary,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Could not load movies from TMDB.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _reload,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final feed = snapshot.data!;
            return RefreshIndicator(
              color: AppTheme.accent,
              onRefresh: _reload,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    title: const Text('KyiKyaMal'),
                    actions: [
                      IconButton(
                        tooltip: 'Search',
                        onPressed: widget.onSearchTap,
                        icon: const Icon(Icons.search_rounded),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: HomeHeroBanner(movies: feed.featured),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: MovieSection(
                      title: 'Trending',
                      movies: feed.trending,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: MovieSection(
                      title: 'Popular',
                      movies: feed.popular,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: MovieSection(
                      title: 'Now Playing',
                      movies: feed.nowPlaying,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: MovieSection(
                      title: 'Upcoming',
                      movies: feed.upcoming,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: MovieSection(
                        title: 'Top Rated',
                        movies: feed.topRated,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: MovieSection(
                      title: 'Trending TV',
                      movies: feed.tvTrending,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: MovieSection(
                      title: 'Popular TV',
                      movies: feed.tvPopular,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: MovieSection(
                      title: 'Top Rated TV',
                      movies: feed.tvTopRated,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: MovieSection(
                        title: 'On The Air',
                        movies: feed.tvOnTheAir,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
