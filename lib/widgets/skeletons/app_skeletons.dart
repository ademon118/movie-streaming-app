import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Opacity(
          opacity: 0.35 + (t * 0.45),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class SkeletonPosterCard extends StatelessWidget {
  const SkeletonPosterCard({super.key, this.width = 120});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: width, height: width * 1.5, borderRadius: 8),
          const SizedBox(height: 8),
          SkeletonBox(width: width * 0.9, height: 12, borderRadius: 4),
          const SizedBox(height: 6),
          SkeletonBox(width: width * 0.4, height: 10, borderRadius: 4),
        ],
      ),
    );
  }
}

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        const SliverAppBar(
          pinned: true,
          title: Text('KyiKyaMal'),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SkeletonBox(
              width: double.infinity,
              height: 210,
              borderRadius: 14,
            ),
          ),
        ),
        ...List.generate(3, (section) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: SkeletonBox(
                      width: 120,
                      height: 16,
                      borderRadius: 4,
                    ),
                  ),
                  SizedBox(
                    height: 260,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 5,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) =>
                          const SkeletonPosterCard(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class SearchResultsSkeleton extends StatelessWidget {
  const SearchResultsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.52,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return SkeletonPosterCard(width: constraints.maxWidth);
          },
        );
      },
    );
  }
}

class PosterGridSkeleton extends StatelessWidget {
  const PosterGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SearchResultsSkeleton();
  }
}

class MovieDetailsSkeleton extends StatelessWidget {
  const MovieDetailsSkeleton({super.key, this.title = ''});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            title: title.isEmpty ? null : Text(title),
            flexibleSpace: FlexibleSpaceBar(
              background: ColoredBox(
                color: AppTheme.scaffoldBackground,
                child: SkeletonBox(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 0,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Expanded(child: SkeletonBox(height: 44, borderRadius: 10)),
                      SizedBox(width: 10),
                      Expanded(child: SkeletonBox(height: 44, borderRadius: 10)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const SkeletonBox(height: 44, borderRadius: 10),
                  const SizedBox(height: 20),
                  const SkeletonBox(width: 100, height: 16, borderRadius: 4),
                  const SizedBox(height: 10),
                  const SkeletonBox(height: 12, borderRadius: 4),
                  const SizedBox(height: 8),
                  const SkeletonBox(height: 12, borderRadius: 4),
                  const SizedBox(height: 8),
                  const SkeletonBox(width: 220, height: 12, borderRadius: 4),
                  const SizedBox(height: 24),
                  const SkeletonBox(width: 60, height: 16, borderRadius: 4),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return const Column(
                          children: [
                            SkeletonBox(
                              width: 56,
                              height: 56,
                              borderRadius: 28,
                            ),
                            SizedBox(height: 8),
                            SkeletonBox(width: 64, height: 10, borderRadius: 4),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
