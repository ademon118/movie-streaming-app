import '../models/movie.dart';

/// Third-party embed hosts for in-app Watch.
enum StreamSource {
  vidking('Vidking'),
  vidsrc('Vidsrc'),
  vidrock('Vidrock');

  const StreamSource(this.label);

  final String label;

  static const all = StreamSource.values;
}

/// Vidking streaming servers that tend to be the most reliable.
enum VidkingServer {
  hydrogen('Hydrogen'),
  oxygen('Oxygen');

  const VidkingServer(this.label);

  final String label;

  static const preferred = [VidkingServer.hydrogen, VidkingServer.oxygen];

  static VidkingServer? tryParse(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    for (final server in VidkingServer.values) {
      if (server.label.toLowerCase() == normalized ||
          server.name == normalized) {
        return server;
      }
    }
    return null;
  }
}

/// Builds player URLs for movie / TV playback embeds and trailers.
///
/// TMDB does **not** stream movies — only metadata / trailers / “where to watch”.
class WatchUrls {
  static const accentColor = 'e0a100';
  static const vidkingHost = 'www.vidking.net';
  static const youtubeReferer = 'https://www.youtube.com/';
  static const youtubeEmbedOrigin = 'https://www.youtube-nocookie.com';

  static bool isVidkingStream(Uri url) => url.host.contains(vidkingHost);

  static bool isYouTube(Uri url) =>
      url.host.contains('youtube.com') ||
      url.host.contains('youtu.be') ||
      url.host.contains('youtube-nocookie.com');

  static Uri streamFor(
    Movie movie, {
    StreamSource source = StreamSource.vidking,
    bool autoPlay = true,
  }) {
    switch (source) {
      case StreamSource.vidking:
        return movie.isTv
            ? vidkingTv(movie.id, autoPlay: autoPlay)
            : vidkingMovie(movie.id, autoPlay: autoPlay);
      case StreamSource.vidsrc:
        return movie.isTv
            ? Uri.parse('https://vidsrc.to/embed/tv/${movie.id}/1/1')
            : Uri.parse('https://vidsrc.to/embed/movie/${movie.id}');
      case StreamSource.vidrock:
        return movie.isTv
            ? Uri.parse(
                'https://vidrock.net/tv/${movie.id}/1/1'
                '?autoplay=true&autonext=true',
              )
            : Uri.parse(
                'https://vidrock.net/movie/${movie.id}?autoplay=true',
              );
    }
  }

  static Uri vidkingMovie(
    String tmdbId, {
    bool autoPlay = true,
    int? progressSeconds,
  }) {
    final query = <String, String>{
      'color': accentColor,
      'autoPlay': autoPlay.toString(),
    };
    if (progressSeconds != null && progressSeconds > 0) {
      query['progress'] = progressSeconds.toString();
    }
    return Uri.https(vidkingHost, '/embed/movie/$tmdbId', query);
  }

  static Uri vidkingTv(
    String tmdbId, {
    int season = 1,
    int episode = 1,
    bool autoPlay = true,
    int? progressSeconds,
  }) {
    final query = <String, String>{
      'color': accentColor,
      'autoPlay': autoPlay.toString(),
      'nextEpisode': 'true',
      'episodeSelector': 'true',
    };
    if (progressSeconds != null && progressSeconds > 0) {
      query['progress'] = progressSeconds.toString();
    }
    return Uri.https(
      vidkingHost,
      '/embed/tv/$tmdbId/$season/$episode',
      query,
    );
  }

  /// Backward-compatible aliases.
  static Uri movieStream(String tmdbId, {bool autoPlay = true}) =>
      vidkingMovie(tmdbId, autoPlay: autoPlay);

  static Uri tvStream(
    String tmdbId, {
    int season = 1,
    int episode = 1,
    bool autoPlay = true,
  }) =>
      vidkingTv(
        tmdbId,
        season: season,
        episode: episode,
        autoPlay: autoPlay,
      );

  static Uri youtubeTrailer(String youtubeKey) {
    return Uri.https(
      'www.youtube-nocookie.com',
      '/embed/$youtubeKey',
      const {
        'autoplay': '1',
        'playsinline': '1',
        'rel': '0',
        'modestbranding': '1',
      },
    );
  }

  static Uri youtubeTrailerApp(String youtubeKey) {
    return Uri.parse('https://www.youtube.com/watch?v=$youtubeKey');
  }

  /// HTML wrapper so the WebView has a real HTTPS origin (fixes Error 153).
  static String youtubeEmbedHtml(String youtubeKey) {
    final src = youtubeTrailer(youtubeKey).toString();
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
  <style>
    html, body { margin: 0; padding: 0; height: 100%; background: #000; overflow: hidden; }
    iframe { position: absolute; inset: 0; width: 100%; height: 100%; border: 0; }
  </style>
</head>
<body>
  <iframe
    src="$src"
    title="Trailer"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
    referrerpolicy="strict-origin-when-cross-origin"
    allowfullscreen
  ></iframe>
</body>
</html>
''';
  }

  /// Injects preferred Vidking server after the embed player initializes.
  static String selectServerScript(VidkingServer server) {
    final names = [
      server.label,
      ...VidkingServer.preferred
          .where((candidate) => candidate != server)
          .map((candidate) => candidate.label),
    ];
    final jsNames = names.map((name) => '"$name"').join(', ');
    return '''
(function() {
  var preferred = [$jsNames];
  var tries = 0;
  var maxTries = 60;

  function sleep(ms) {
    return new Promise(function(resolve) { setTimeout(resolve, ms); });
  }

  async function pickServer(name) {
    if (typeof window.handleServerChangeDirectly !== 'function') {
      return false;
    }
    var servers = window.availableServers || [];
    var entry = servers.find(function(s) {
      return s && s.name && s.name.toLowerCase() === name.toLowerCase();
    });
    if (!entry) {
      return false;
    }
    try {
      if (typeof window.testServerAvailability === 'function') {
        var ok = await window.testServerAvailability(name);
        if (ok) return true;
      }
      await window.handleServerChangeDirectly(name);
      return true;
    } catch (e) {
      console.warn('Failed selecting server', name, e);
      return false;
    }
  }

  async function run() {
    tries += 1;
    if (typeof window.handleServerChangeDirectly !== 'function') {
      if (tries < maxTries) {
        await sleep(400);
        return run();
      }
      return;
    }
    for (var i = 0; i < preferred.length; i += 1) {
      if (await pickServer(preferred[i])) {
        return;
      }
      await sleep(300);
    }
  }

  run();
})();
''';
  }
}
