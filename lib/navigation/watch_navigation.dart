import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/watch_urls.dart' show StreamSource, VidkingServer, WatchUrls;
import '../models/movie.dart';
import '../screens/watch_player_screen.dart';

Future<void> openMovieWatch(BuildContext context, Movie movie) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => WatchPlayerScreen(
        title: movie.title,
        subtitle: null,
        movie: movie,
        url: WatchUrls.streamFor(movie),
        initialSource: StreamSource.vidking,
        preferredServer: VidkingServer.hydrogen,
      ),
    ),
  );
}

Future<void> openMovieTrailer(
  BuildContext context, {
  required Movie movie,
  String? youtubeKey,
}) async {
  if (youtubeKey == null || youtubeKey.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No trailer available for this title'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => WatchPlayerScreen(
        title: movie.title,
        subtitle: 'Trailer',
        url: WatchUrls.youtubeTrailer(youtubeKey),
        youtubeKey: youtubeKey,
      ),
    ),
  );
}

Future<void> openTrailerExternally(String youtubeKey) async {
  final uri = WatchUrls.youtubeTrailerApp(youtubeKey);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
