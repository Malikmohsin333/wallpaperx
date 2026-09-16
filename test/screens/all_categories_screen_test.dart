import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaperx/screens/all_categories_screen.dart';

void main() {
  final categories = [
    {
      'name': 'Nature',
      'color': 0xFF4CAF50,
      'icon': Icons.nature,
      'count': '120 wallpapers',
    },
    {
      'name': 'Cars',
      'color': 0xFF2196F3,
      'icon': Icons.directions_car,
      'count': '85 wallpapers',
    },
    {
      'name': 'Space',
      'color': 0xFF9C27B0,
      'icon': Icons.rocket_launch,
      'count': '64 wallpapers',
    },
  ];

  testWidgets(
    'AllCategoriesScreen displays categories correctly',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AllCategoriesScreen(
            categories: categories,
            onCategoryTap: (_) {},
          ),
        ),
      );

      expect(find.text('All Categories'), findsOneWidget);
      expect(find.text('Nature'), findsOneWidget);
      expect(find.text('Cars'), findsOneWidget);
      expect(find.text('Space'), findsOneWidget);

      expect(find.text('120 wallpapers'), findsOneWidget);
      expect(find.text('85 wallpapers'), findsOneWidget);
      expect(find.text('64 wallpapers'), findsOneWidget);

      expect(find.byIcon(Icons.nature), findsOneWidget);
      expect(find.byIcon(Icons.directions_car), findsOneWidget);
      expect(find.byIcon(Icons.rocket_launch), findsOneWidget);
    },
  );

  testWidgets(
    'AllCategoriesScreen calls onCategoryTap when a category is tapped',
    (tester) async {
      String? selectedCategory;

      await tester.pumpWidget(
        MaterialApp(
          home: AllCategoriesScreen(
            categories: categories,
            onCategoryTap: (categoryName) {
              selectedCategory = categoryName;
            },
          ),
        ),
      );

      expect(selectedCategory, isNull);

      await tester.tap(find.text('Cars'));
      await tester.pumpAndSettle();

      expect(selectedCategory, 'Cars');
    },
  );
}
