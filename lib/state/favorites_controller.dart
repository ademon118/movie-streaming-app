import 'package:flutter/foundation.dart';

import '../models/movie.dart';

class FavoritesController extends ChangeNotifier {
  FavoritesController();

  final List<Movie> _items = [];

  List<Movie> get items => List.unmodifiable(_items);

  bool containsMovie(Movie movie) =>
      _items.any((item) => item.favoriteKey == movie.favoriteKey);

  void add(Movie movie) {
    if (containsMovie(movie)) return;
    _items.insert(0, movie);
    notifyListeners();
  }

  void remove(Movie movie) {
    final before = _items.length;
    _items.removeWhere((item) => item.favoriteKey == movie.favoriteKey);
    if (_items.length != before) notifyListeners();
  }

  void toggle(Movie movie) {
    if (containsMovie(movie)) {
      remove(movie);
    } else {
      add(movie);
    }
  }
}
