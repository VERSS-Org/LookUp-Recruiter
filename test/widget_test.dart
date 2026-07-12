import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lookup_flutter/BarraNavegacion.dart';
import 'package:lookup_flutter/main.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/services/contacto_service.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/services/postulacion_service.dart';
import 'package:lookup_flutter/services/profile_service.dart';
import 'package:lookup_flutter/services/puesto_service.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';
import 'package:lookup_flutter/theme/lookup_widgets.dart';

class _FakeContactoService extends ContactoService {
  @override
  Future<void> fetchBandeja({bool notify = true}) async {}
}

class _FakePostulacionService extends PostulacionService {
  @override
  Future<void> fetchEventos({bool notify = true}) async {}
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _testShell() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthService()),
      ChangeNotifierProvider(create: (_) => ProfileService()),
      ChangeNotifierProvider(create: (_) => PuestoService()),
      ChangeNotifierProvider<PostulacionService>(
        create: (_) => _FakePostulacionService(),
      ),
      ChangeNotifierProvider<ContactoService>(
        create: (_) => _FakeContactoService(),
      ),
      ChangeNotifierProvider(create: (_) => LocaleController()),
    ],
    child: MaterialApp(
      theme: buildLookUpTheme(Brightness.light),
      home: const BarraNavegacion(),
    ),
  );
}

void main() {
  testWidgets('shows the recruiter login screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido a LookUp'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });

  testWidgets('mobile shell keeps messages left and alerts by profile', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(360, 800));

    await tester.pumpWidget(_testShell());
    await tester.pump(const Duration(milliseconds: 100));

    final chatX = tester.getCenter(find.byTooltip('Mensajes')).dx;
    final logoX = tester.getCenter(find.byType(BrandMark)).dx;
    final notificationX = tester.getCenter(find.byTooltip('Notificaciones')).dx;
    final profileX = tester.getCenter(find.byType(InitialsAvatar)).dx;

    expect(chatX, lessThan(logoX));
    expect(notificationX, lessThan(profileX));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('desktop shell orders messages, alerts and profile at 1440px', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(1440, 900));

    await tester.pumpWidget(_testShell());
    await tester.pump(const Duration(milliseconds: 100));

    final messageX = tester.getCenter(find.byTooltip('Mensajes')).dx;
    final notificationX = tester.getCenter(find.byTooltip('Notificaciones')).dx;
    final profileX = tester.getCenter(find.byType(InitialsAvatar)).dx;

    expect(find.text('LookUp'), findsNothing);
    expect(messageX, lessThan(notificationX));
    expect(notificationX, lessThan(profileX));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
