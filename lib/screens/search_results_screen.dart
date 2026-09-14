import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'detail_screen.dart';
import '../models/wallpaper.dart';
import '../services/api_service.dart';

class SearchResultsScreen extends StatefulWidget {
  final String searchQuery;

  const SearchResultsScreen({
    super.key,
    required this.searchQuery,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<Wallpaper> results = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  String? errorMessage;
  int currentPage = 1;
  bool hasMore = true;

  final ApiService _apiService = ApiService();
    final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    performSearch();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore && hasMore && !isLoading) {
        loadMoreResults();
      }
    }
  }

  Future<void> performSearch({bool reset = true}) async {
    if (reset) {
      setState(() {
        isLoading = true;
        currentPage = 1;
        results = [];
        hasMore = true;
        errorMessage = null;
      });
    }

    try {
      final randomPage =
          DateTime.now().millisecondsSinceEpoch % 10 + currentPage;

      final newResults = await _apiService.searchWallpapers(
        query: widget.searchQuery,
        page: randomPage,
        perPage: 8,
      );

      if (mounted) {
        setState(() {
          if (reset) {
            results = newResults;
          } else {
            results.addAll(newResults);
          }

          isLoading = false;
          isLoadingMore = false;
          hasMore = newResults.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');

      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
          errorMessage = 'Failed to load search results';
        });
      }
    }
  }
  Future<void> loadMoreResults() async {
    setState(() {
      isLoadingMore = true;
    });

    currentPage++;
    await performSearch(reset: false);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Search: ${widget.searchQuery}'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _buildBody(isDarkMode),
    );
  }

  Widget _buildBody(bool isDarkMode) {
    if (isLoading && results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(seconds: 1),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 3.14159 * 2,
                  child: const CircularProgressIndicator(),
                );
              },
            ),
            const SizedBox(height: 16),
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.2, end: 1),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: const Text('Searching...'),
                );
              },
            ),
          ],
        ),
      );
    }

    if (errorMessage != null && results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => performSearch(reset: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (results.isEmpty && !isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Try a different keyword',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: results.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == results.length && isLoadingMore) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final wallpaper = results[index];
        final String imageUrl = wallpaper.mediumUrl;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    DetailScreen(photo: wallpaper),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;

                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(
                    CurveTween(curve: curve),
                  );

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                child: const Icon(
                  Icons.error,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CustomSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    close(context, query);
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search,
              size: 64, color: isDarkMode ? Colors.grey : Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Search for wallpapers',
            style:
                TextStyle(color: isDarkMode ? Colors.grey : Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'e.g., Mountains, Cars, Pakistan',
            style:
                TextStyle(color: isDarkMode ? Colors.grey : Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}








