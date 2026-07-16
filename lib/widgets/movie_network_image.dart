import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// TMDB poster/backdrop with disk cache, size fallbacks, and auto-retry.
class MovieNetworkImage extends StatefulWidget {
  const MovieNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.iconSize = 32,
    this.borderRadius,
  });

  /// Disabled in widget tests to avoid pending retry timers.
  static bool autoRetryOnError = true;

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double iconSize;
  final BorderRadius? borderRadius;

  @override
  State<MovieNetworkImage> createState() => _MovieNetworkImageState();
}

class _MovieNetworkImageState extends State<MovieNetworkImage> {
  static const _sizeFallbacks = <String, String>{
    '/w780/': '/w500/',
    '/w500/': '/w342/',
    '/w342/': '/w185/',
  };

  late List<String> _candidates;
  var _candidateIndex = 0;
  var _retryScheduled = false;
  var _failedCandidateIndex = -1;

  @override
  void initState() {
    super.initState();
    _candidates = _buildCandidates(widget.url);
  }

  @override
  void didUpdateWidget(covariant MovieNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _candidates = _buildCandidates(widget.url);
      _candidateIndex = 0;
      _retryScheduled = false;
      _failedCandidateIndex = -1;
    }
  }

  List<String> _buildCandidates(String url) {
    if (url.isEmpty) return const [];
    final candidates = <String>[url];
    var current = url;
    while (true) {
      String? next;
      for (final entry in _sizeFallbacks.entries) {
        if (current.contains(entry.key)) {
          next = current.replaceFirst(entry.key, entry.value);
          break;
        }
      }
      if (next == null || candidates.contains(next)) break;
      candidates.add(next);
      current = next;
    }
    return candidates;
  }

  String? get _activeUrl {
    if (_candidates.isEmpty || _candidateIndex >= _candidates.length) {
      return null;
    }
    return _candidates[_candidateIndex];
  }

  int? get _memCacheWidth {
    final width = widget.width;
    if (width == null) return null;
    return (width * MediaQuery.devicePixelRatioOf(context)).round();
  }

  void _scheduleRetry() {
    if (!MovieNetworkImage.autoRetryOnError) return;
    if (_retryScheduled || !mounted) return;
    if (_candidateIndex >= _candidates.length - 1) return;
    _retryScheduled = true;
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      _retryScheduled = false;
      setState(() => _candidateIndex += 1);
    });
  }

  void _retryNow() {
    if (_candidateIndex >= _candidates.length - 1) return;
    setState(() {
      _retryScheduled = false;
      _candidateIndex += 1;
    });
  }

  Widget _placeholder({bool showSpinner = true}) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: AppTheme.posterPlaceholder,
      alignment: Alignment.center,
      child: showSpinner
          ? SizedBox(
              width: widget.iconSize * 0.65,
              height: widget.iconSize * 0.65,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.accent,
              ),
            )
          : Icon(
              Icons.movie_outlined,
              color: AppTheme.textSecondary,
              size: widget.iconSize,
            ),
    );
  }

  Widget _error({required bool canRetry}) {
    return GestureDetector(
      onTap: canRetry ? _retryNow : null,
      child: Container(
        width: widget.width,
        height: widget.height,
        color: AppTheme.posterPlaceholder,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.movie_outlined,
              color: AppTheme.textSecondary,
              size: widget.iconSize,
            ),
            if (canRetry) ...[
              const SizedBox(height: 6),
              Text(
                'Tap to retry',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = _activeUrl;
    if (url == null || url.isEmpty) {
      return _error(canRetry: false);
    }

    final image = CachedNetworkImage(
      key: ValueKey('$url-$_candidateIndex'),
      imageUrl: url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      memCacheWidth: _memCacheWidth,
      maxWidthDiskCache: _memCacheWidth,
      fadeInDuration: const Duration(milliseconds: 220),
      placeholder: (context, url) => _placeholder(),
      errorWidget: (context, url, error) {
        if (_failedCandidateIndex != _candidateIndex) {
          _failedCandidateIndex = _candidateIndex;
          _scheduleRetry();
        }
        final canRetry = _candidateIndex < _candidates.length - 1;
        return _error(canRetry: canRetry);
      },
    );

    if (widget.borderRadius == null) return image;

    return ClipRRect(
      borderRadius: widget.borderRadius!,
      child: image,
    );
  }
}
