import 'package:flutter/material.dart';

import '../models/movie.dart';
import 'movie_poster_card.dart';

class MoviePosterGrid extends StatelessWidget {
  const MoviePosterGrid({
    super.key,
    required this.movies,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
  });

  final List<Movie> movies;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.52,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return MoviePosterCard(
              movie: movies[index],
              width: constraints.maxWidth,
            );
          },
        );
      },
    );
  }
}
