import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/movie_repository.dart';
import '../models/movie.dart';
import '../state/movie_repository_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_poster_grid.dart';
import '../widgets/skeletons/app_skeletons.dart';

enum SearchCategory { movie, tvShows, actor }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late MovieRepository _repository;
  var _repoReady = false;

  SearchCategory _category = SearchCategory.movie;
  String _query = '';
  late List<String> _recent;
  List<Movie> _results = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _recent = <String>[];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repoReady) return;
    _repoReady = true;
    _repository = MovieRepositoryScope.of(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<List<Movie>> _fetchResults(String query, SearchCategory category) {
    switch (category) {
      case SearchCategory.movie:
        return _repository.searchMovies(query);
      case SearchCategory.tvShows:
        return _repository.searchTvShows(query);
      case SearchCategory.actor:
        return Future.value(const []);
    }
  }

  Future<void> _runSearch(String raw) async {
    final value = raw.trim();
    setState(() {
      _query = value;
      _controller.text = value;
      _controller.selection = TextSelection.collapsed(offset: value.length);
      if (value.isNotEmpty) {
        _recent.removeWhere((item) => item.toLowerCase() == value.toLowerCase());
        _recent.insert(0, value);
        if (_recent.length > 8) _recent = _recent.take(8).toList();
        _loading = true;
      } else {
        _results = const [];
        _loading = false;
      }
    });

    if (value.isEmpty) return;

    final category = _category;
    final results = await _fetchResults(value, category);
    if (!mounted || _query.trim() != value || _category != category) return;
    setState(() {
      _results = results;
      _loading = false;
    });
    _focusNode.unfocus();
  }

  void _selectCategory(SearchCategory category) {
    if (_category == category) return;
    setState(() => _category = category);
    if (_query.trim().isNotEmpty) {
      _runSearch(_query);
    }
  }

  void _clearQuery() {
    setState(() {
      _query = '';
      _controller.clear();
      _results = const [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final showResults = _query.trim().isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Search',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  if (value.trim().isEmpty) {
                    _clearQuery();
                  } else {
                    setState(() => _query = value);
                  }
                },
                onSubmitted: _runSearch,
                style: const TextStyle(color: AppTheme.textPrimary),
                cursorColor: AppTheme.accent,
                decoration: InputDecoration(
                  hintText: 'Movies, TV shows, genres…',
                  hintStyle: const TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.surfaceElevated,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          onPressed: _clearQuery,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CategoryChip(
                    label: 'Movie',
                    icon: Icons.movie_outlined,
                    selected: _category == SearchCategory.movie,
                    onTap: () => _selectCategory(SearchCategory.movie),
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: 'TV Shows',
                    icon: Icons.tv_outlined,
                    selected: _category == SearchCategory.tvShows,
                    onTap: () => _selectCategory(SearchCategory.tvShows),
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: 'Actor',
                    icon: Icons.person_outline_rounded,
                    selected: _category == SearchCategory.actor,
                    onTap: () => _selectCategory(SearchCategory.actor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: showResults
                  ? _loading
                      ? const SearchResultsSkeleton()
                      : _SearchResultsBody(
                          category: _category,
                          results: _results,
                          query: _query.trim(),
                        )
                  : _SearchIdleBody(
                      recent: _recent,
                      onRecentTap: _runSearch,
                      onClearRecent: () => setState(_recent.clear),
                      onRemoveRecent: (value) {
                        setState(() => _recent.remove(value));
                      },
                      onPopularTap: _runSearch,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? AppTheme.scaffoldBackground : AppTheme.textSecondary,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? AppTheme.scaffoldBackground : AppTheme.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      selectedColor: AppTheme.accent,
      backgroundColor: AppTheme.surfaceElevated,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _SearchIdleBody extends StatelessWidget {
  const _SearchIdleBody({
    required this.recent,
    required this.onRecentTap,
    required this.onClearRecent,
    required this.onRemoveRecent,
    required this.onPopularTap,
  });

  final List<String> recent;
  final ValueChanged<String> onRecentTap;
  final VoidCallback onClearRecent;
  final ValueChanged<String> onRemoveRecent;
  final ValueChanged<String> onPopularTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (recent.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'Recent searches',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton(
                onPressed: onClearRecent,
                child: const Text(
                  'Clear',
                  style: TextStyle(color: AppTheme.accent),
                ),
              ),
            ],
          ),
          ...recent.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.history_rounded,
                color: AppTheme.textSecondary,
              ),
              title: Text(item),
              trailing: IconButton(
                tooltip: 'Remove',
                onPressed: () => onRemoveRecent(item),
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
              ),
              onTap: () => onRecentTap(item),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Popular searches',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: popularSearchQueries
              .map(
                (query) => ActionChip(
                  label: Text(query),
                  backgroundColor: AppTheme.surfaceElevated,
                  side: BorderSide.none,
                  labelStyle: const TextStyle(color: AppTheme.textPrimary),
                  onPressed: () => onPopularTap(query),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SearchResultsBody extends StatelessWidget {
  const _SearchResultsBody({
    required this.category,
    required this.results,
    required this.query,
  });

  final SearchCategory category;
  final List<Movie> results;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (category == SearchCategory.actor) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Actor search coming soon',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            category == SearchCategory.tvShows
                ? 'No TV shows found for “$query”'
                : 'No movies found for “$query”',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ),
      );
    }

    return MoviePosterGrid(movies: results);
  }
}
