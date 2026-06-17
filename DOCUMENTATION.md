# 📱 WallpaperX - HD Wallpaper App

---

## 🎯 Overview

WallpaperX is a complete, production-ready Flutter app for Android that lets users browse, download, share, and set HD & 4K wallpapers.  Hive local storage, and a beautiful modern UI with dark/light mode support. No backend required.

**Tech Stack:** Flutter 3.x, Dart 3.x, Pexels API, Hive, Provider

---

## ✨ Features

Browse HD & 4K Wallpapers | 16 Categories (Nature, Cars, Abstract, Space, Animals, Mountains, Beaches, etc.) | Search Wallpapers | Favorites (Offline Storage) | Download to Gallery | Share via WhatsApp/Instagram | Set as Home/Lock/Both Wallpaper | Dark/Light Mode | Recently Viewed (Last 20) | 4-Step Onboarding | Rate Us Dialog | Clear Cache | Share App Link | Pull to Refresh | Pagination (Load More) | Portrait Wallpapers Only | Smooth Animations | Duplicate Prevention on Scroll

---

## 📋 Requirements

- Flutter: 3.x
- Dart: 3.x
- Android SDK: API 21 (Minimum) / API 34 (Target)
- IDE: VS Code / Android Studio
- Device: Android 5.0+

---

## 🛠️ Installation

```bash
git clone https://github.com/yourusername/wallpaperx.git
cd wallpaperx
flutter pub get
flutter run
🔑 Change API Key
Step 1: Get your free API key from: https://www.pexels.com/api/

Step 2: Open lib/main.dart

Step 3: Find this line (around line 130):

dart
final String apiKey = "RtUKoEjPl5GFEONmMJ3kuphBxPWWLWuOFFvkeipPa6sCXrsMoqxTLOxc";
Step 4: Replace with your new API key:

dart
final String apiKey = "YOUR_NEW_API_KEY_HERE";
Note: Pexels API is completely free. Sign up at Pexels.com and generate your key from the API dashboard.

📱 Build APK
bash
flutter clean
flutter pub get
flutter build apk --release
APK Location: build/app/outputs/flutter-apk/app-release.apk (~49 MB)

📂 Project Structure
text
wallpaperx/
├── lib/
│   ├── main.dart                         # Main app (Home, Search, Detail, Favorites)
│   ├── screens/
│   │   ├── splash_screen.dart            # Animated splash screen
│   │   └── onboarding_screen.dart        # 4-step onboarding
│   └── widgets/
│       └── shimmer_loading_grid.dart     # Loading shimmer
├── android/
│   └── app/
│       └── src/
│           └── main/
│               ├── AndroidManifest.xml   # All permissions (Internet, Storage, Set Wallpaper)
│               ├── res/
│               │   ├── values/
│               │   │   └── styles.xml    # Fullscreen theme (edge-to-edge display)
│               │   └── xml/
│               │       └── file_paths.xml # FileProvider for wallpaper set
│               └── kotlin/
│                   └── com/
│                       └── example/
│                           └── wallpaperx/
│                               └── MainActivity.kt # Native code for wallpaper set & download
├── assets/
│   └── icon/
│       └── app_icon.png                  # 1024x1024 app icon
├── pubspec.yaml                          # All dependencies
└── README.md                             # This file
🔧 Android Permissions (Already Configured in AndroidManifest.xml)
xml
<!-- Internet -->
<uses-permission android:name="android.permission.INTERNET"/>

<!-- Wallpaper Set -->
<uses-permission android:name="android.permission.SET_WALLPAPER" />

<!-- Storage (Android 12 and below) -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

<!-- Android 13+ -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
📦 Dependencies (Already in pubspec.yaml)
Package	Version	Purpose
dio	^5.3.0	HTTP requests to Pexels API
cached_network_image	^3.2.3	Image caching & loading
provider	^6.1.1	State management
hive_flutter	^1.1.0	Local storage for favorites
share_plus	^7.2.2	Share wallpapers
permission_handler	^11.0.0	Storage permission handling
connectivity_plus	^6.0.3	Internet connection check
shared_preferences	^2.2.2	Theme & onboarding preference
url_launcher	^6.2.5	Open Play Store link
shimmer	^3.0.0	Shimmer loading effect
🎯 All Features Breakdown
Feature	Status	Description
HD Wallpapers	✅	Pexels API, 8 wallpapers per page
16 Categories	✅	Nature, Cars, Abstract, Space, Animals, Mountains, Beaches, etc.
Search	✅	Keyword search with results
Favorites	✅	Hive local storage (works offline)
Download	✅	Save wallpapers to phone gallery
Share	✅	Share via WhatsApp, Instagram, etc.
Set Wallpaper	✅	Set as Home, Lock, or Both screens
Dark/Light Mode	✅	Toggle theme + auto-save preference
Recently Viewed	✅	Track last 20 wallpapers viewed
Onboarding	✅	4-step guide for new users
Splash Screen	✅	Animated: logo zoom, pulse ring, text slide
Full Screen	✅	Edge-to-edge display with notch support
Rate Us	✅	Shows after 5 downloads
Pagination	✅	Load more on scroll
Portrait Only	✅	Only portrait wallpapers shown
Duplicate Prevention	✅	No repeats on scroll
Animated Loading	✅	Bouncing dots while loading
Clear Cache	✅	Clear cached images
Share App	✅	Share app link with friends
Pull to Refresh	✅	Refresh wallpapers by pulling down
🐛 Troubleshooting
Build fails with "Permission denied"

bash
Remove-Item -Recurse -Force build
flutter clean
flutter pub get
flutter build apk --release
App not full screen
Check android/app/src/main/res/values/styles.xml has:

xml
<item name="android:windowFullscreen">true</item>
<item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>
Wallpaper set not working
Ensure android/app/src/main/res/xml/file_paths.xml exists:

xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <cache-path name="cache" path="." />
    <external-cache-path name="external_cache" path="." />
</paths>
APK not installing on phone
Go to Settings → Security → Install from unknown sources → Allow

Storage permission denied (Android 13+)
Settings → Apps → WallpaperX → Permissions → Storage → Allow

Pexels API not working

Check API key in lib/main.dart

Ensure internet connection

Check API key status at: https://www.pexels.com/dashboard/

Gradle taking too long

bash
cd android && ./gradlew clean && cd ..
flutter clean
flutter pub get
flutter build apk --release
Packages not resolving

bash
flutter pub cache repair
flutter pub get
📱 App Flow
App Launch → Splash Screen (3s animation) → Onboarding (if first time) → Home Screen (Categories + Wallpapers) → Tap Wallpaper → Detail Screen (Full view + Download/Share/Set options) → Back to Home → Favorites (Offline saved wallpapers) → Search (Search by keyword)

📄 License
This app is sold as a complete product with full source code. The buyer receives full ownership and can use it for personal or commercial purposes.

Made with ❤️ using Flutter