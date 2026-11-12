import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/widgets/user_avatar.dart';

void main() {
  group('UserAvatar Widget Tests', () {
    testWidgets('renders two-letter initials when photoUrl is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(name: 'Amul Bhatia'),
          ),
        ),
      );

      expect(find.text('AB'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('renders single initial when singleInitial is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              name: 'Amul Bhatia',
              photoUrl: '   ',
              singleInitial: true,
            ),
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('renders Image widget when valid photoUrl is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              name: 'Amul Bhatia',
              photoUrl: 'https://example.com/uploads/avatars/amul.jpg',
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });
  });
}

