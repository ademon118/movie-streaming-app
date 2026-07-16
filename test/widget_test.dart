import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movie_app/main.dart';
import 'package:movie_app/screens/categories_screen.dart';
import 'package:movie_app/screens/favorites_screen.dart';
import 'package:movie_app/screens/main_shell.dart';
import 'package:movie_app/screens/movie_details_screen.dart';
import 'package:movie_app/screens/profile_screen.dart';
import 'package:movie_app/screens/search_screen.dart';

import 'fake_movie_repository.dart';
import 'package:movie_app/widgets/movie_network_image.dart';

void main() {
  setUpAll(() {
    MovieNetworkImage.autoRetryOnError = false;
  });

  Widget app() => MovieApp(repository: FakeMovieRepository());

  testWidgets('MainShell shows Home with Trending section', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text('Trending'), findsOneWidget);
    expect(find.text('KyiKyaMal'), findsOneWidget);
  });

  testWidgets('Search tab shows popular searches', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Search').last);
    await tester.pumpAndSettle();

    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.text('Popular searches'), findsOneWidget);
  });

  testWidgets('Search filters TV shows by query', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Search').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('TV Shows'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Test');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Test TV Show'), findsWidgets);
  });

  testWidgets('Search filters movies by query', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Search').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Test');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Test Movie'), findsWidgets);
  });

  testWidgets('Favorites tab shows empty saved count', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();

    expect(find.byType(FavoritesScreen), findsOneWidget);
    expect(find.textContaining('saved'), findsOneWidget);
  });

  testWidgets('Categories tab lists genres', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();

    expect(find.byType(CategoriesScreen), findsOneWidget);
    expect(find.text('Action'), findsOneWidget);
    expect(find.text('Comedy'), findsOneWidget);
  });

  testWidgets('Profile tab shows user and settings entry', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Watch History'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Tapping a home poster opens Movie Details', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Test Movie').first);
    await tester.pumpAndSettle();

    expect(find.byType(MovieDetailsScreen), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Cast'), findsOneWidget);
  });
}
