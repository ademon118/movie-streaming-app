import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../data/watch_urls.dart';
import '../models/movie.dart';
import '../theme/app_theme.dart';

class WatchPlayerScreen extends StatefulWidget {
  const WatchPlayerScreen({
    super.key,
    required this.title,
    required this.url,
    this.subtitle,
    this.movie,
    this.initialSource = StreamSource.vidking,
    this.preferredServer = VidkingServer.hydrogen,
    this.youtubeKey,
  });

  final String title;
  final Uri url;
  final String? subtitle;
  final Movie? movie;
  final StreamSource initialSource;
  final VidkingServer preferredServer;

  /// When set, trailer is loaded via HTML embed (avoids YouTube Error 153).
  final String? youtubeKey;

  @override
  State<WatchPlayerScreen> createState() => _WatchPlayerScreenState();
}

class _WatchPlayerScreenState extends State<WatchPlayerScreen> {
  late final WebViewController _controller;
  late StreamSource _selectedSource;
  late VidkingServer _selectedServer;
  late Uri _activeUrl;
  var _loading = true;
  var _controlsVisible = true;
  String? _error;
  Timer? _hideTimer;

  bool get _isStreamPlayer => widget.youtubeKey == null;
  bool get _isVidkingStream =>
      _isStreamPlayer && WatchUrls.isVidkingStream(_activeUrl);
  bool get _isYouTubeTrailer =>
      widget.youtubeKey != null || WatchUrls.isYouTube(widget.url);

  @override
  void initState() {
    super.initState();
    _selectedSource = widget.initialSource;
    _selectedServer = widget.preferredServer;
    _activeUrl = widget.movie != null
        ? WatchUrls.streamFor(widget.movie!, source: _selectedSource)
        : widget.url;
    _controller = _createController();
    _loadContent();
    if (_isStreamPlayer) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      _scheduleHideControls();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    if (_isStreamPlayer) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  void _scheduleHideControls() {
    _hideTimer?.cancel();
    if (!_isStreamPlayer) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || !_controlsVisible || _error != null) return;
      setState(() => _controlsVisible = false);
    });
  }

  void _showControls() {
    setState(() => _controlsVisible = true);
    _scheduleHideControls();
  }

  void _hideControls() {
    _hideTimer?.cancel();
    if (!_controlsVisible) return;
    setState(() => _controlsVisible = false);
  }

  WebViewController _createController() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.scaffoldBackground)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _loading = true;
                _error = null;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _loading = false);
            }
            if (_isVidkingStream) {
              _applyPreferredServer();
            }
            if (_isStreamPlayer) {
              _scheduleHideControls();
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame != true) return;
            if (!mounted) return;
            setState(() {
              _loading = false;
              _error = error.description;
              _controlsVisible = true;
            });
          },
          onNavigationRequest: (request) => NavigationDecision.navigate,
        ),
      );

    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      platform.setMediaPlaybackRequiresUserGesture(false);
    }
    if (platform is WebKitWebViewController) {
      platform.setAllowsBackForwardNavigationGestures(true);
    }

    controller.setUserAgent(
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 '
      'Mobile/15E148 Safari/604.1',
    );

    return controller;
  }

  Future<void> _loadContent() async {
    final key = widget.youtubeKey;
    if (key != null && key.isNotEmpty) {
      await _controller.loadHtmlString(
        WatchUrls.youtubeEmbedHtml(key),
        baseUrl: WatchUrls.youtubeEmbedOrigin,
      );
      return;
    }

    if (_isYouTubeTrailer) {
      await _controller.loadRequest(
        _activeUrl,
        headers: const {'Referer': WatchUrls.youtubeReferer},
      );
      return;
    }

    await _controller.loadRequest(_activeUrl);
  }

  Future<void> _applyPreferredServer() async {
    try {
      await _controller.runJavaScript(
        WatchUrls.selectServerScript(_selectedServer),
      );
    } catch (_) {}
  }

  Future<void> _onSourceSelected(StreamSource source) async {
    if (_selectedSource == source || widget.movie == null) return;
    setState(() {
      _selectedSource = source;
      _activeUrl = WatchUrls.streamFor(widget.movie!, source: source);
      _error = null;
      _loading = true;
      _controlsVisible = true;
    });
    _scheduleHideControls();
    await _loadContent();
  }

  Future<void> _onServerSelected(VidkingServer server) async {
    if (_selectedServer == server) return;
    setState(() {
      _selectedServer = server;
      _loading = true;
      _controlsVisible = true;
    });
    _scheduleHideControls();
    await _applyPreferredServer();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _reloadPlayer() async {
    setState(() {
      _error = null;
      _loading = true;
      _controlsVisible = true;
    });
    _scheduleHideControls();
    await _loadContent();
  }

  Future<void> _openExternally() async {
    final Uri uri;
    if (widget.youtubeKey != null && widget.youtubeKey!.isNotEmpty) {
      uri = WatchUrls.youtubeTrailerApp(widget.youtubeKey!);
    } else {
      uri = _activeUrl;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildHeader() {
    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_isStreamPlayer && widget.movie != null)
                PopupMenuButton<StreamSource>(
                  tooltip: 'Stream source',
                  initialValue: _selectedSource,
                  onSelected: _onSourceSelected,
                  icon: const Icon(Icons.cloud_outlined, color: Colors.white),
                  itemBuilder: (context) {
                    return StreamSource.all
                        .map(
                          (source) => PopupMenuItem(
                            value: source,
                            child: Row(
                              children: [
                                if (source == _selectedSource)
                                  const Icon(
                                    Icons.check,
                                    size: 18,
                                    color: AppTheme.accent,
                                  )
                                else
                                  const SizedBox(width: 18),
                                const SizedBox(width: 8),
                                Text(source.label),
                              ],
                            ),
                          ),
                        )
                        .toList();
                  },
                ),
              if (_isVidkingStream)
                PopupMenuButton<VidkingServer>(
                  tooltip: 'Vidking server',
                  initialValue: _selectedServer,
                  onSelected: _onServerSelected,
                  icon: const Icon(Icons.dns_outlined, color: Colors.white),
                  itemBuilder: (context) {
                    return VidkingServer.preferred
                        .map(
                          (server) => PopupMenuItem(
                            value: server,
                            child: Row(
                              children: [
                                if (server == _selectedServer)
                                  const Icon(
                                    Icons.check,
                                    size: 18,
                                    color: AppTheme.accent,
                                  )
                                else
                                  const SizedBox(width: 18),
                                const SizedBox(width: 8),
                                Text(server.label),
                              ],
                            ),
                          ),
                        )
                        .toList();
                  },
                ),
              IconButton(
                tooltip:
                    _isYouTubeTrailer ? 'Open in YouTube' : 'Open in browser',
                onPressed: _openExternally,
                icon: const Icon(Icons.open_in_new, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final showChrome =
        !_isStreamPlayer || _controlsVisible || _error != null || _loading;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_error == null)
            WebViewWidget(controller: _controller)
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.textSecondary,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load player.\n$_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _reloadPlayer,
                      child: const Text('Retry'),
                    ),
                    if (_isStreamPlayer && widget.movie != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          final next = StreamSource.all.firstWhere(
                            (s) => s != _selectedSource,
                            orElse: () => StreamSource.vidsrc,
                          );
                          _onSourceSelected(next);
                        },
                        child: const Text('Try another source'),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _openExternally,
                      child: Text(
                        _isYouTubeTrailer
                            ? 'Open in YouTube'
                            : 'Open in browser',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            ),
          // Tap top of screen to show header again.
          if (_isStreamPlayer && !showChrome)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topInset + 72,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _showControls,
              ),
            ),
          // Tap just under header to hide it (WebView stays usable).
          if (_isStreamPlayer && showChrome && _error == null && !_loading)
            Positioned(
              top: topInset + kToolbarHeight,
              left: 0,
              right: 0,
              height: 48,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideControls,
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            top: showChrome ? 0 : -(topInset + kToolbarHeight + 8),
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: showChrome ? 1 : 0,
              child: IgnorePointer(
                ignoring: !showChrome,
                child: _buildHeader(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
