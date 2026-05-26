import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lookup_flutter/main.dart';

void main() {
  testWidgets('shows the recruiter login screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido a LookUp'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
