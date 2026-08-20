import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/app_model.dart';
import '../../../data/repositories/app_repository.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/download_service.dart';
import '../../bloc/app_bloc.dart';
import '../../bloc/download_bloc.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/shimmer_loading.dart';
import 'app_detail_screen.dart';
import 'category_apps_screen.dart';
import 'package:devstore/core/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AppBloc(context.read<AppRepository>())..add(const LoadFeaturedApps()),
        ),
        BlocProvider(
          create: (context) => AppBloc(context.read<AppRepository>())..add(const LoadNewReleases()),
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.black,
        body: CustomScrollView(
          slivers: [
            const SliverAppBar(
              floating: true,
              pinned: true,
              expandedHeight: 120,
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              centerTitle: false,
              title: Text(
                'Aᴘᴘ Sᴛᴏʀᴇ',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: ColoredBox(color: Colors.black),
              ),
            ),
            SliverToBoxAdapter(
              child: BlocBuilder<AppBloc, AppState>(
                builder: (context, state) {
                  if (state is AppLoading) return const ShimmerFeaturedSection();
                  if (state is AppError) return Center(child: Text('Error: ${state.message}', style: const TextStyle(color: Colors.white)));
                  if (state is AppsLoaded && state.apps.isNotEmpty) return _buildFeaturedSection(context, state.apps);
                  return const SizedBox.shrink();
                },
              ),
            ),
            SliverToBoxAdapter(child: _buildCategoriesSection(context)),
            SliverToBoxAdapter(
              child: BlocBuilder<AppBloc, AppState>(
                builder: (context, state) {
                  if (state is AppLoading) return const ShimmerAppList();
                  if (state is AppError) return Center(child: Text('Error: ${state.message}', style: const TextStyle(color: Colors.white)));
                  if (state is AppsLoaded && state.apps.isNotEmpty) return _buildNewReleasesSection(context, state.apps);
                  return const SizedBox.shrink();
                },
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSection(BuildContext context, List<AppModel> apps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Featured', onSeeAll: null),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: apps.length,
            itemBuilder: (context, index) => _FeaturedAppCard(app: apps[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Categories', onSeeAll: null),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: AppConstants.appCategories.length - 1,
            itemBuilder: (context, index) {
              final category = AppConstants.appCategories[index + 1];
              return _CategoryChip(
                category: category,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CategoryAppsScreen(category: category))),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewReleasesSection(BuildContext context, List<AppModel> apps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'New Releases', onSeeAll: null),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: apps.length,
          itemBuilder: (context, index) => AppCard(
            app: apps[index],
            onTap: () => _navigateToAppDetail(context, apps[index]),
          ),
        ),
      ],
    );
  }

  // FIXED: Navigate with per-app DownloadBloc
  void _navigateToAppDetail(BuildContext context, AppModel app) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (context) => DownloadBloc(
            context.read<DownloadService>(),
            context.read<AppRepository>(),
          ),
          child: AppDetailScreen(app: app),
        ),
      ),
    );
  }
}

class _FeaturedAppCard extends StatelessWidget {
  final AppModel app;
  const _FeaturedAppCard({required this.app});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => const HomeScreen()._navigateToAppDetail(context, app),
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF111111),
          border: Border.all(color: Colors.white24),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: app.iconUrl.isNotEmpty
                    ? Image.network(
                        app.iconUrl,
                        fit: BoxFit.cover,
                        opacity: const AlwaysStoppedAnimation(0.3),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(color: const Color(0xFF1A1A1A));
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.primary.withOpacity(0.2),
                            child: const Center(
                              child: Icon(Icons.android, color: Colors.white24, size: 48),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: AppColors.primary.withOpacity(0.2),
                        child: const Center(
                          child: Icon(Icons.android, color: Colors.white24, size: 48),
                        ),
                      ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'FEATURED',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    app.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    app.developerName,
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        app.averageRating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        app.downloadCount.toString(),
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      const Text('downloads', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  final VoidCallback onTap;
  const _CategoryChip({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.apps, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              category,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
