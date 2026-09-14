import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/wallpaper.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/shimmer_loading_grid.dart';
import '../widgets/wallpaper_card.dart';
import '../state/theme_provider.dart';
import '../state/wallpaper_provider.dart';
import 'detail_screen.dart';
import 'search_results_screen.dart';
import 'favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<Wallpaper> wallpapers = [];
  List<dynamic> recentlyViewed = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  String? errorMessage;
  String currentCategory = "Curated";
  int currentPage = 1;
  bool hasMore = true;
  bool isConnected = true;
  int downloadCount = 0;
  late AnimationController _greetingController;
  late Animation<double> _greetingAnimation;

  // FIX: getter to access isDarkMode from context where needed
  WallpaperProvider get wallpaperProvider =>
    Provider.of<WallpaperProvider>(context, listen: false);

  bool get isDarkMode =>
      Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

  final String apiKey = dotenv.env['PEXELS_API_KEY'] ?? '';

  final List<Map<String, dynamic>> mainCategories = [
    {'name': 'Curated', 'icon': Icons.trending_up, 'color': 0xFF6366F1},
    {'name': '4K Ultra HD', 'icon': Icons.four_k, 'color': 0xFFEF4444},
    {
      'name': 'Trending',
      'icon': Icons.local_fire_department,
      'color': 0xFFF59E0B
    },
    {'name': 'New', 'icon': Icons.fiber_new, 'color': 0xFF10B981},
    {'name': 'Random', 'icon': Icons.shuffle, 'color': 0xFF8B5CF6},
  ];

  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Nature',
      'icon': Icons.forest,
      'count': '40+',
      'color': 0xFF10B981
    },
    {
      'name': 'City',
      'icon': Icons.location_city,
      'count': '32+',
      'color': 0xFF3B82F6
    },
    {
      'name': 'Cars',
      'icon': Icons.directions_car,
      'count': '48+',
      'color': 0xFFEF4444
    },
    {
      'name': 'Abstract',
      'icon': Icons.auto_awesome,
      'count': '56+',
      'color': 0xFF8B5CF6
    },
    {
      'name': 'Space',
      'icon': Icons.rocket,
      'count': '24+',
      'color': 0xFF06B6D4
    },
    {
      'name': 'Animals',
      'icon': Icons.pets,
      'count': '32+',
      'color': 0xFFF59E0B
    },
    {
      'name': 'Mountains',
      'icon': Icons.terrain,
      'count': '28+',
      'color': 0xFF10B981
    },
    {
      'name': 'Beaches',
      'icon': Icons.beach_access,
      'count': '20+',
      'color': 0xFF06B6D4
    },
    {'name': 'Forest', 'icon': Icons.park, 'count': '36+', 'color': 0xFF10B981},
    {
      'name': 'Technology',
      'icon': Icons.computer,
      'count': '44+',
      'color': 0xFF8B5CF6
    },
    {
      'name': 'Gaming',
      'icon': Icons.sports_esports,
      'count': '52+',
      'color': 0xFFEC4899
    },
    {'name': 'Art', 'icon': Icons.brush, 'count': '38+', 'color': 0xFFF59E0B},
    {
      'name': 'Music',
      'icon': Icons.music_note,
      'count': '26+',
      'color': 0xFFEF4444
    },
    {
      'name': 'Sports',
      'icon': Icons.sports_soccer,
      'count': '30+',
      'color': 0xFF3B82F6
    },
    {
      'name': 'Travel',
      'icon': Icons.flight,
      'count': '42+',
      'color': 0xFF6366F1
    },
    {
      'name': 'Food',
      'icon': Icons.restaurant,
      'count': '34+',
      'color': 0xFFF59E0B
    },
  ];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _greetingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _greetingAnimation = CurvedAnimation(
      parent: _greetingController,
      curve: Curves.easeInOut,
    );
    _greetingController.forward();
    _checkInternetAndLoad();
    _loadRecentlyViewed();
    _scrollController.addListener(_onScroll);
    _checkAndShowRateDialog();
  }

  Widget _buildAnimatedLoadingDots() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.3, end: 1.0),
              duration: Duration(milliseconds: 500 + (index * 150)),
              builder: (context, double value, child) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 12 * value,
                  height: 12 * value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6366F1).withValues(alpha: value),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _greetingController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentlyViewed() async {
    final recentlyViewedBox = Hive.box('recently_viewed');
    setState(() {
      recentlyViewed = recentlyViewedBox.values.toList().reversed.toList();
      if (recentlyViewed.length > 20) {
        recentlyViewed = recentlyViewed.sublist(0, 20);
      }
    });
  }

  Future<void> _addToRecentlyViewed(dynamic photo) async {
    final recentlyViewedBox = Hive.box('recently_viewed');
    final id = photo['id'].toString();

    if (recentlyViewedBox.containsKey(id)) {
      recentlyViewedBox.delete(id);
    }

    await recentlyViewedBox.put(id, photo);

    if (recentlyViewedBox.length > 20) {
      final keys = recentlyViewedBox.keys.toList();
      await recentlyViewedBox.delete(keys[0]);
    }

    await _loadRecentlyViewed();
  }

  Future<void> _checkAndShowRateDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final downloadCount = prefs.getInt('download_count') ?? 0;
    final hasRated = prefs.getBool('has_rated') ?? false;

    if (downloadCount >= 5 && !hasRated && mounted) {
      _showRateDialog();
    }
  }

  void _showRateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enjoying WallpaperX?'),
        content:
            const Text('Please rate us on the Play Store and help us improve!'),
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('has_rated', true);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('No, Thanks'),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('has_rated', true);
              const url =
                  'https://play.google.com/store/apps/details?id=com.example.wallpaperx';
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url));
              }
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Rate Now',
                style: TextStyle(color: Color(0xFF6366F1))),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      await tempDir.delete(recursive: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to clear cache')),
        );
      }
    }
  }

  void _shareApp() {
    Share.share(
      'Check out WallpaperX - The best HD wallpaper app!\n\n'
      'Download now: https://play.google.com/store/apps/details?id=com.example.wallpaperx',
    );
  }

  String _getGreeting() {
    return 'Welcome Back';
  }

  String _getCategoryCount() {
    final mainCategoryNames = mainCategories.map((c) => c['name']).toSet();
    if (mainCategoryNames.contains(currentCategory)) {
      return '${wallpapers.length}+';
    }
    final match = categories.firstWhere(
      (c) => c['name'] == currentCategory,
      orElse: () => {'count': '${wallpapers.length}+'},
    );
    return match['count'];
  }

  Future<void> _checkInternetAndLoad() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      setState(() {
        isConnected = false;
        isLoading = false;
        errorMessage = 'No internet connection.\nPlease check your connection.';
      });
    } else {
      setState(() {
        isConnected = true;
      });
      await wallpaperProvider.loadWallpapers(
        category: currentCategory,
        refresh: true,
      );

      if (mounted) {
        setState(() {
          wallpapers = wallpaperProvider.wallpapers;
          isLoading = wallpaperProvider.isLoading;
          hasMore = wallpaperProvider.hasMore;
          errorMessage = wallpaperProvider.error;
        });
      }    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (!isLoadingMore && hasMore && !isLoading && isConnected) {
        loadMoreWallpapers();
      }
    }
  }

  Future<void> loadMoreWallpapers() async {
    if (wallpaperProvider.isLoading || !wallpaperProvider.hasMore) return;

    setState(() {
      isLoadingMore = true;
    });

    await wallpaperProvider.loadMoreWallpapers(
      category: currentCategory,
    );

    if (mounted) {
      setState(() {
        wallpapers = wallpaperProvider.wallpapers;
        isLoadingMore = wallpaperProvider.isLoading;
        hasMore = wallpaperProvider.hasMore;
        errorMessage = wallpaperProvider.error;
      });
    }
  }
  void _onSearch(String query) {
    if (query.trim().isNotEmpty && isConnected) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              SearchResultsScreen(searchQuery: query),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
                position: animation.drive(tween), child: child);
          },
        ),
      );
    } else if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection')),
      );
    }
  }

  Future<void> _onCategoryTap(String category) async {
    if (isConnected) {
      setState(() {
        currentCategory = category;
        isLoading = true;
        isLoadingMore = false;
        errorMessage = null;
      });

      await wallpaperProvider.loadWallpapers(
        category: category,
        refresh: true,
      );

      if (mounted) {
        setState(() {
          wallpapers = wallpaperProvider.wallpapers;
          isLoading = wallpaperProvider.isLoading;
          hasMore = wallpaperProvider.hasMore;
          errorMessage = wallpaperProvider.error;
          isConnected = wallpaperProvider.error == null;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection')),
      );
    }
  }
  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.clear_all, color: Color(0xFF6366F1)),
              title: const Text('Clear Cache'),
              onTap: () {
                Navigator.pop(context);
                _clearCache();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Color(0xFF6366F1)),
              title: const Text('Share App'),
              onTap: () {
                Navigator.pop(context);
                _shareApp();
              },
            ),
            ListTile(
              leading: const Icon(Icons.star, color: Color(0xFF6366F1)),
              title: const Text('Rate Us'),
              onTap: () {
                Navigator.pop(context);
                _showRateDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAnimatedMessage(String message, {bool isSuccess = true}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 80,
        left: 20,
        right: 20,
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSuccess ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () => overlayEntry.remove());
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode; // FIX: declared properly here

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        title: FadeTransition(
          opacity: _greetingAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const Text(
                'WallpaperX',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => themeProvider.toggleTheme(),
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
            onPressed: _showSettingsMenu,
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            onPressed: () async {
              if (isConnected) {
                final result = await showSearch<String>(
                  context: context,
                  delegate: CustomSearchDelegate(),
                );
                if (result != null && result.isNotEmpty) {
                  _onSearch(result);
                }
              } else {
                _showAnimatedMessage('No internet connection',
                    isSuccess: false);
              }
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const FavoritesScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    var tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));
                    return SlideTransition(
                        position: animation.drive(tween), child: child);
                  },
                ),
              );
            },
            icon: const Icon(Icons.favorite_border),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _checkInternetAndLoad();
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Categories Row
                if (isConnected)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 0, 0),
                    child: SizedBox(
                      height: 70,
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.white,
                              Colors.white,
                              Colors.transparent
                            ],
                            stops: [0.0, 0.88, 1.0],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(right: 32),
                          itemCount: mainCategories.length,
                          itemBuilder: (context, index) {
                            final category = mainCategories[index];
                            final isSelected =
                                currentCategory == category['name'];
                            return GestureDetector(
                              onTap: () => _onCategoryTap(category['name']),
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF6366F1)
                                      : (isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[100]),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      category['icon'],
                                      size: 18,
                                      color: isSelected
                                          ? Colors.white
                                          : Color(category['color']),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      category['name'],
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : (isDarkMode
                                                ? Colors.white
                                                : Colors.black),
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                // Welcome Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        isConnected
                            ? 'Discover Beautiful\nWallpapers'
                            : 'No Internet\nConnection',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Recently Viewed Section
                if (recentlyViewed.isNotEmpty && isConnected)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recently Viewed',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final recentlyViewedBox =
                                    Hive.box('recently_viewed');
                                await recentlyViewedBox.clear();
                                await _loadRecentlyViewed();
                              },
                              child: const Text('Clear',
                                  style: TextStyle(color: Color(0xFF6366F1))),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 120,
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white,
                                Colors.white,
                                Colors.transparent
                              ],
                              stops: [0.0, 0.88, 1.0],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.dstIn,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(16, 0, 32, 0),
                            itemCount: recentlyViewed.length > 10
                                ? 10
                                : recentlyViewed.length,
                            itemBuilder: (context, index) {
                              final photo = recentlyViewed[index];
                              final String imageUrl = photo['src']['small'];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                          DetailScreen(photo: photo),
                                      transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) {
                                        const begin = Offset(0.0, 1.0);
                                        const end = Offset.zero;
                                        const curve = Curves.easeInOut;
                                        var tween = Tween(
                                                begin: begin, end: end)
                                            .chain(CurveTween(curve: curve));
                                        return SlideTransition(
                                            position: animation.drive(tween),
                                            child: child);
                                      },
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 80,
                                  height: 120,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          Container(color: Colors.grey[300]),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                // Categories Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      //  TextButton(
                      //   onPressed: _showAllCategories,
                      //  child: const Text('See All',
                      //   style: TextStyle(color: Color(0xFF6366F1))),
                      //),
                    ],
                  ),
                ),
                SizedBox(
                  height: 110,
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white,
                          Colors.white,
                          Colors.transparent
                        ],
                        stops: [0.0, 0.88, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 32, 0),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = currentCategory == category['name'];
                        return GestureDetector(
                          onTap: () => _onCategoryTap(category['name']),
                          child: Container(
                            width: 90,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: Color(category['color'])
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: isSelected
                                  ? Border.all(
                                      color: Color(category['color']), width: 2)
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  category['icon'],
                                  size: 32,
                                  color: Color(category['color']),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  category['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                Text(
                                  '${category['count']}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Trending Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Trending Now',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      if (isConnected)
                        Text(
                          '${_getCategoryCount()} Wallpapers',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                    ],
                  ),
                ),

                // Wallpapers Grid or No Internet Message
                isConnected
                    ? _buildWallpapersGrid(isDarkMode)
                    : _buildNoInternetMessage(isDarkMode),

                if (isLoadingMore && isConnected) _buildAnimatedLoadingDots(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoInternetMessage(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.wifi_off,
            size: 80,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Internet Connection',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection\nand try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _checkInternetAndLoad,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('Retry'),
          ),
          const SizedBox(height: 40),
          Text(
            'Your favorites are still available!',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const FavoritesScreen()),
              );
            },
            icon: const Icon(Icons.favorite_border, color: Color(0xFF6366F1)),
            label: const Text(
              'View Favorites',
              style: TextStyle(color: Color(0xFF6366F1)),
            ),
          ),
        ],
      ),
    );
  }

  // FIX: pass isDarkMode from build context using Theme
  Widget _buildAnimatedLoadingGrid() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return ShimmerLoadingGrid(isDarkMode: isDarkMode);
  }

  Widget _buildWallpapersGrid(bool isDarkMode) {
    if (isLoading && wallpapers.isEmpty) {
      return _buildAnimatedLoadingGrid();
    }

    if (errorMessage != null && wallpapers.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.error, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(errorMessage!),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });

                await wallpaperProvider.loadWallpapers(
                  category: currentCategory,
                  refresh: true,
                );

                if (mounted) {
                  setState(() {
                    wallpapers = wallpaperProvider.wallpapers;
                    isLoading = wallpaperProvider.isLoading;
                    hasMore = wallpaperProvider.hasMore;
                    errorMessage = wallpaperProvider.error;
                  });
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (wallpapers.isEmpty) {
      return const Center(child: Text('No wallpapers found'));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: wallpapers.length,
      itemBuilder: (context, index) {
        final photo = wallpapers[index];

        return WallpaperCard(
          wallpaper: photo,
          isDarkMode: isDarkMode,
          onTap: () async {
            await _addToRecentlyViewed(photo);

            if (!context.mounted) return;

            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    DetailScreen(photo: photo),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
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
        );
      },
    );
  }
}














