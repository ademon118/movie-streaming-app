import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../screens/movie_details_screen.dart';

Future<void> openMovieDetails(BuildContext context, Movie movie) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => MovieDetailsScreen(movie: movie),
    ),
  );
}
