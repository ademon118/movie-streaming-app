import 'package:flutter/material.dart';

import '../data/movie_repository.dart';

class MovieRepositoryScope extends InheritedWidget {
  const MovieRepositoryScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final MovieRepository repository;

  static MovieRepository of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<MovieRepositoryScope>();
    assert(scope != null, 'MovieRepositoryScope not found');
    return scope!.repository;
  }

  static MovieRepository read(BuildContext context) {
    final scope = context
        .getElementForInheritedWidgetOfExactType<MovieRepositoryScope>()
        ?.widget as MovieRepositoryScope?;
    assert(scope != null, 'MovieRepositoryScope not found');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(MovieRepositoryScope oldWidget) {
    return repository != oldWidget.repository;
  }
}
