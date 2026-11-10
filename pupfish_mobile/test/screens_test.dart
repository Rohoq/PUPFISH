import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pupfish_mobile/screens/home_screen.dart';
import 'package:pupfish_mobile/screens/post_detail_screen.dart';
import 'package:pupfish_mobile/screens/game_details_screen.dart';

void main() {
  testWidgets('HomeScreen displays all main destination cards including posts and platforms',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Katalog gier'), findsOneWidget);
    expect(find.text('Moja biblioteka'), findsOneWidget);
    expect(find.text('Dyskusje i posty'), findsOneWidget);
    expect(find.text('Moje platformy'), findsOneWidget);
  });

  testWidgets('PostDetailScreen displays post title, author, content and comments section',
      (WidgetTester tester) async {
    final mockPost = {
      'id': 1,
      'title': 'Testowy post o grze',
      'content': 'To jest przykładowa treść posta do testów.',
      'username': 'tester123',
      'created_at': '2026-11-10T10:00:00Z',
      'game': 1,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(post: mockPost),
      ),
    );
    await tester.pump();

    expect(find.text('Testowy post o grze'), findsWidgets);
    expect(find.text('tester123'), findsOneWidget);
    expect(find.text('To jest przykładowa treść posta do testów.'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget); // Comment input
  });

  testWidgets('GameDetailsScreen displays game name, sections for news, comments and posts link',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockGame = {
      'id': 1,
      'name': 'Wiedźmin 3: Dziki Gon',
      'release_date': '2015-05-19',
      'rating': 9.5,
      'cover_url': null,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: GameDetailsScreen(game: mockGame),
      ),
    );
    await tester.pump();

    expect(find.text('Wiedźmin 3: Dziki Gon'), findsWidgets);
    expect(find.text('Data premiery'), findsOneWidget);
    expect(find.text('2015-05-19'), findsOneWidget);
    expect(find.text('Dyskusje i posty o tej grze'), findsOneWidget);
    expect(find.text('Aktualności ze Steam'), findsOneWidget);
  });
}
