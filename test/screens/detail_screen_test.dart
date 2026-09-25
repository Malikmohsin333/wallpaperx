import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive_test/hive_test.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:wallpaperx/services/image_download_service.dart';

import 'package:wallpaperx/models/wallpaper.dart';
import 'package:wallpaperx/screens/detail_screen.dart';
import 'package:wallpaperx/widgets/wallpaper_option.dart';

class _FakePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async {
    return Directory.current.path;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    return Directory.current.path;
  }
}

class _FakeSharePlatform extends SharePlatform {
  final bool shouldThrow;

  _FakeSharePlatform({
    this.shouldThrow = false,
  });

  @override
  Future<ShareResult> share(ShareParams params) async {
    if (shouldThrow) {
      throw Exception('Test share failure');
    }

    return ShareResult(
      'shared',
      ShareResultStatus.success,
    );
  }
}

class _FakeImageDownloadService extends ImageDownloadService {
  final Uint8List bytes;
  final bool shouldThrow;
  bool downloadCalled = false;

  _FakeImageDownloadService({
    Uint8List? bytes,
    this.shouldThrow = false,
  }) : bytes = bytes ?? Uint8List.fromList([1, 2, 3, 4]);

  @override
  Future<Uint8List> downloadImage(String imageUrl) async {
    downloadCalled = true;

    if (shouldThrow) {
      throw Exception('Test download failure');
    }

    return bytes;
  }
}

class _FakePermissionHandler extends PermissionHandlerPlatform {
  PermissionStatus photosStatus;
  PermissionStatus storageStatus;
  final bool grantOnRequest;

  _FakePermissionHandler({
    required this.photosStatus,
    required this.storageStatus,
    this.grantOnRequest = false,
  });

  @override
  Future<PermissionStatus> checkPermissionStatus(
    Permission permission,
  ) async {
    if (permission == Permission.photos) {
      return photosStatus;
    }

    if (permission == Permission.storage) {
      return storageStatus;
    }

    return PermissionStatus.denied;
  }

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async {
    if (grantOnRequest) {
      photosStatus = PermissionStatus.granted;
      storageStatus = PermissionStatus.granted;
    }

    return {
      for (final permission in permissions)
        permission: permission == Permission.photos
            ? photosStatus
            : permission == Permission.storage
                ? storageStatus
                : PermissionStatus.denied,
    };
  }

  @override
  Future<bool> openAppSettings() async {
    photosStatus = PermissionStatus.granted;
    storageStatus = PermissionStatus.granted;
    return false;
  }
}

Wallpaper _wallpaper() {
  return Wallpaper(
    id: 123,
    photographer: 'Test Photographer',
    originalUrl: 'https://example.com/original.jpg',
    largeUrl: 'https://example.com/large.jpg',
    mediumUrl: 'https://example.com/medium.jpg',
    portraitUrl: 'https://example.com/portrait.jpg',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Box favoritesBox;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});

    await setUpTestHive();
    favoritesBox = await Hive.openBox('favorites');

    const pathProviderChannel =
        MethodChannel('plugins.flutter.io/path_provider');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      pathProviderChannel,
      (MethodCall methodCall) async {
        return Directory.current.path;
      },
    );

    const permissionChannel =
        MethodChannel('flutter.baseflow.com/permissions/methods');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      permissionChannel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'checkPermissionStatus':
            return 1;
          case 'requestPermissions':
            return <int, int>{};
          case 'openAppSettings':
            return false;
          default:
            return null;
        }
      },
    );
  });

  setUp(() {
    favoritesBox.clear();

    final fakeHandler = _FakePermissionHandler(
      photosStatus: PermissionStatus.granted,
      storageStatus: PermissionStatus.granted,
    );

    PermissionHandlerPlatform.instance = fakeHandler;
    PathProviderPlatform.instance = _FakePathProvider();
  });

  testWidgets('share wallpaper shows failure when sharing throws',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(
          photo: _wallpaper(),
          imageDownloadService: _FakeImageDownloadService(),
          sharePlus: SharePlus.custom(
            _FakeSharePlatform(shouldThrow: true),
          ),
        ),
      ),
    );

    await tester.pump();
    final shareText = find.text('Share');
    expect(shareText, findsOneWidget);
    await tester.tap(shareText);
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    expect(find.text('Failed to share wallpaper'), findsOneWidget);

    // Dispose the tree, then let the image cache cleanup timer (10s) fire
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('share wallpaper succeeds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(
          photo: _wallpaper(),
          imageDownloadService: _FakeImageDownloadService(),
          sharePlus: SharePlus.custom(
            _FakeSharePlatform(),
          ),
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.text('Share'));

    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(find.text('Shared successfully'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('download saves image successfully', (tester) async {
    const downloadChannel = MethodChannel('download_channel');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      downloadChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'saveToGallery') {
          return 'success';
        }

        return null;
      },
    );

    final downloadService = _FakeImageDownloadService();

    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(
          photo: _wallpaper(),
          imageDownloadService: downloadService,
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.text('Download'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Wallpaper Saved to Gallery'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(downloadChannel, null);
  });

  testWidgets('download shows failure when gallery save fails', (tester) async {
    const downloadChannel = MethodChannel('download_channel');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      downloadChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'saveToGallery') {
          return 'failed';
        }

        return null;
      },
    );

    final downloadService = _FakeImageDownloadService();

    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(
          photo: _wallpaper(),
          imageDownloadService: downloadService,
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.text('Download'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Failed to save wallpaper'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(downloadChannel, null);
  });

  testWidgets('download requests permission and succeeds', (tester) async {
    const downloadChannel = MethodChannel('download_channel');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      downloadChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'saveToGallery') {
          return 'success';
        }

        return null;
      },
    );

    PermissionHandlerPlatform.instance = _FakePermissionHandler(
      photosStatus: PermissionStatus.denied,
      storageStatus: PermissionStatus.denied,
      grantOnRequest: true,
    );

    final downloadService = _FakeImageDownloadService();

    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(
          photo: _wallpaper(),
          imageDownloadService: downloadService,
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.text('Download'));

    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(find.text('Wallpaper Saved to Gallery'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 11));

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(downloadChannel, null);
  });
  testWidgets('download shows failure when image download throws',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(
          photo: _wallpaper(),
          imageDownloadService: _FakeImageDownloadService(
            shouldThrow: true,
          ),
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.text('Download'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Failed to save wallpaper'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
  });
  testWidgets('download returns when photos permission is already granted',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(photo: _wallpaper()),
      ),
    );

    await tester.pump();

    await tester.tap(find.text('Download'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Storage Permission Required'), findsNothing);
  });

  testWidgets('download returns when storage permission is already granted',
      (tester) async {
    const permissionChannel =
        MethodChannel('flutter.baseflow.com/permissions/methods');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      permissionChannel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'checkPermissionStatus':
            if (methodCall.arguments == 9) {
              return 0;
            }
            return 1;
          case 'requestPermissions':
            return <int, int>{};
          case 'openAppSettings':
            return false;
          default:
            return null;
        }
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(photo: _wallpaper()),
      ),
    );

    await tester.pump();

    await tester.tap(find.text('Download'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Storage Permission Required'), findsNothing);
  });

  testWidgets('download shows permission dialog when permissions are denied',
      (tester) async {
    PermissionHandlerPlatform.instance = _FakePermissionHandler(
      photosStatus: PermissionStatus.denied,
      storageStatus: PermissionStatus.denied,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(photo: _wallpaper()),
      ),
    );

    await tester.pump();

    await tester.tap(find.text('Download'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Storage Permission Required'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Storage Permission Required'), findsNothing);
  });

  testWidgets('permission dialog open settings path is handled',
      (tester) async {
    PermissionHandlerPlatform.instance = _FakePermissionHandler(
      photosStatus: PermissionStatus.denied,
      storageStatus: PermissionStatus.denied,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(photo: _wallpaper()),
      ),
    );

    await tester.pump();

    await tester.tap(find.text('Download'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Storage Permission Required'), findsOneWidget);

    await tester.tap(find.text('Open Settings'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Storage Permission Required'), findsNothing);
  });

  testWidgets('renders detail screen actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(photo: _wallpaper()),
      ),
    );

    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Set as'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });

  testWidgets('back button pops detail screen', (tester) async {
    final observer = NavigatorObserver();

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailScreen(photo: _wallpaper()),
                  ),
                );
              },
              child: const Text('Open Detail'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Detail'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Download'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Open Detail'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  testWidgets('adds wallpaper to favorites', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(photo: _wallpaper()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(favoritesBox.get('123'), isNotNull);
  });

  testWidgets('removes wallpaper from favorites', (tester) async {
    favoritesBox.put('123', {
      'id': 1,
      'photographer': 'Existing',
      'src': {
        'original': 'https://example.com/original.jpg',
        'large': 'https://example.com/large.jpg',
        'medium': 'https://example.com/medium.jpg',
        'portrait': 'https://example.com/portrait.jpg',
      },
    });

    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(photo: _wallpaper()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byIcon(Icons.favorite), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(favoritesBox.get('1'), isNull);
  });

  testWidgets('set wallpaper shows failure when method channel throws',
      (tester) async {
    const channel = MethodChannel('wallpaper_channel');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'setWallpaper') {
        throw PlatformException(
          code: 'TEST_FAILURE',
          message: 'Test wallpaper failure',
        );
      }

      return null;
    });

    final downloadService = _FakeImageDownloadService();

    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(
          photo: _wallpaper(),
          imageDownloadService: downloadService,
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.text('Set as'));
    await tester.pump();

    final homeOption = find.byType(WallpaperOption).first;
    expect(homeOption, findsOneWidget);

    final wallpaperOption = tester.widget<WallpaperOption>(homeOption);

    await tester.runAsync(() async {
      wallpaperOption.onTap();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });

    await tester.pump();

    expect(downloadService.downloadCalled, isTrue);
    expect(find.text('Failed to set wallpaper'), findsOneWidget);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('set wallpaper options uses light theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        themeMode: ThemeMode.light,
        home: DetailScreen(
          photo: _wallpaper(),
          imageDownloadService: _FakeImageDownloadService(),
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.text('Set as'));
    await tester.pump();

    expect(find.text('Set as Wallpaper'), findsOneWidget);
    expect(find.text('Home Screen'), findsOneWidget);
    expect(find.text('Lock Screen'), findsOneWidget);
    expect(find.text('Both'), findsOneWidget);

    final sheet = tester.widget<BottomSheet>(
      find.byType(BottomSheet),
    );

    expect(sheet.backgroundColor, isNotNull);
  });
  testWidgets('set wallpaper options uses dark theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        themeMode: ThemeMode.dark,
        home: DetailScreen(
          photo: _wallpaper(),
          imageDownloadService: _FakeImageDownloadService(),
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.text('Set as'));
    await tester.pump();

    expect(find.text('Set as Wallpaper'), findsOneWidget);
    expect(find.text('Home Screen'), findsOneWidget);
    expect(find.text('Lock Screen'), findsOneWidget);
    expect(find.text('Both'), findsOneWidget);

    final sheet = tester.widget<BottomSheet>(
      find.byType(BottomSheet),
    );

    expect(sheet.backgroundColor, equals(Colors.grey[900]));
  });
  testWidgets('sets wallpaper on both screens shows failure when setting fails',
      (tester) async {
    const channel = MethodChannel('wallpaper_channel');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'setWallpaperDirect') {
        return false;
      }

      return null;
    });

    final downloadService = _FakeImageDownloadService();

    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(
          photo: _wallpaper(),
          imageDownloadService: downloadService,
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.text('Set as'));
    await tester.pump();

    final bothOption = find.byType(WallpaperOption).last;
    expect(bothOption, findsOneWidget);

    final wallpaperOption = tester.widget<WallpaperOption>(bothOption);

    await tester.runAsync(() async {
      wallpaperOption.onTap();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });

    await tester.pump();

    expect(downloadService.downloadCalled, isTrue);
    expect(find.text('Failed to set wallpaper'), findsOneWidget);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('sets wallpaper on lock screen successfully', (tester) async {
    const channel = MethodChannel('wallpaper_channel');

    var channelCalled = false;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'setWallpaper') {
        channelCalled = true;
        return true;
      }

      return null;
    });

    final downloadService = _FakeImageDownloadService();

    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(
          photo: _wallpaper(),
          imageDownloadService: downloadService,
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.text('Set as'));
    await tester.pump();

    final lockOption = find.byType(WallpaperOption).at(1);
    expect(lockOption, findsOneWidget);

    final wallpaperOption = tester.widget<WallpaperOption>(lockOption);

    await tester.runAsync(() async {
      wallpaperOption.onTap();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });

    await tester.pump();

    expect(downloadService.downloadCalled, isTrue);
    expect(channelCalled, isTrue);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  testWidgets('sets wallpaper on home screen successfully', (tester) async {
    const channel = MethodChannel('wallpaper_channel');

    var channelCalled = false;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'setWallpaper') {
        channelCalled = true;
        return true;
      }

      return null;
    });

    final downloadService = _FakeImageDownloadService();

    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(
          photo: _wallpaper(),
          imageDownloadService: downloadService,
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.text('Set as'));
    await tester.pump();

    final homeOption = find.byType(WallpaperOption).first;
    expect(homeOption, findsOneWidget);

    final wallpaperOption = tester.widget<WallpaperOption>(homeOption);

    await tester.runAsync(() async {
      wallpaperOption.onTap();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });

    await tester.pump();

    expect(downloadService.downloadCalled, isTrue);
    expect(channelCalled, isTrue);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  testWidgets('sets wallpaper on both screens successfully', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const channel = MethodChannel('wallpaper_channel');
    var channelCalled = false;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'setWallpaperDirect') {
        channelCalled = true;
        return true;
      }

      return null;
    });

    final downloadService = _FakeImageDownloadService();

    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(
          photo: _wallpaper(),
          imageDownloadService: downloadService,
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.text('Set as'));
    await tester.pump();

    expect(find.text('Set as Wallpaper'), findsOneWidget);
    expect(find.text('Home Screen'), findsOneWidget);
    expect(find.text('Lock Screen'), findsOneWidget);
    expect(find.text('Both'), findsOneWidget);
    final bothOption = find.byType(WallpaperOption).last;

    expect(bothOption, findsOneWidget);

    final wallpaperOption = tester.widget<WallpaperOption>(bothOption);
    await tester.runAsync(() async {
      wallpaperOption.onTap();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    await tester.pump();

    expect(downloadService.downloadCalled, isTrue);
    expect(channelCalled, isTrue);
    expect(find.text('Wallpaper Set Successfully!'), findsOneWidget);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
