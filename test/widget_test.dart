// Smoke test minimal — un test end-to-end complet de DonVieApp nécessite
// un mock Firebase (Firebase.initializeApp() est appelé dans main(), pas
// dans le widget), ce qui est hors scope de cette passe. On vérifie ici
// qu'un widget partagé sans dépendance Firebase se construit correctement.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_emergency/core/widgets/primary_button.dart';

void main() {
  testWidgets('PrimaryButton affiche son label et réagit au tap', (
    WidgetTester tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: 'Se connecter',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Se connecter'), findsOneWidget);

    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('PrimaryButton affiche un spinner en état de chargement', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: 'Se connecter',
            isLoading: true,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Se connecter'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
