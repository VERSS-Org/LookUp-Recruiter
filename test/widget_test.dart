import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lookup_flutter/BarraNavegacion.dart';
import 'package:lookup_flutter/Perfil/views/PerfilPage.dart';
import 'package:lookup_flutter/Puesto/views/PuestoForm.dart';
import 'package:lookup_flutter/main.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/services/contacto_service.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/services/postulacion_service.dart';
import 'package:lookup_flutter/services/profile_service.dart';
import 'package:lookup_flutter/services/puesto_service.dart';
import 'package:lookup_flutter/services/theme_controller.dart';
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

class _FakeAuthService extends AuthService {
  @override
  String? get cuentaId => 'empresa-test';
}

class _FakeProfileService extends ProfileService {
  _FakeProfileService()
      : _profile = {
          'cuenta_id': 'empresa-test',
          'nombre_completo': ' Empresa Prueba ',
          'email': ' empresa@lookup.test ',
          'telefono': '+51 999 888 777',
          'ciudad': ' Lima ',
          'perfil': <String, dynamic>{},
        };

  Map<String, dynamic> _profile;
  Map<String, dynamic>? lastUpdates;

  @override
  Map<String, dynamic>? get profileData => _profile;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  Future<Map<String, dynamic>?> fetchProfile(String cuentaId) async => _profile;

  @override
  Future<bool> updateProfile(
    String cuentaId,
    Map<String, dynamic> updates,
  ) async {
    lastUpdates = Map<String, dynamic>.from(updates);
    _profile = {..._profile, ...updates};
    notifyListeners();
    return true;
  }
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

Widget _vacancyFormShell() {
  return ChangeNotifierProvider(
    create: (_) => LocaleController(),
    child: MaterialApp(
      theme: buildLookUpTheme(Brightness.light),
      home: Scaffold(
        body: SingleChildScrollView(
          child: PuestoForm(
            submitLabel: 'Guardar',
            submittingLabel: 'Guardando',
            onSubmit: (_) async => true,
          ),
        ),
      ),
    ),
  );
}

Widget _profileShell(
  _FakeProfileService profileService, {
  bool showBack = false,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthService>(create: (_) => _FakeAuthService()),
      ChangeNotifierProvider<ProfileService>.value(value: profileService),
      ChangeNotifierProvider(create: (_) => ThemeController()),
      ChangeNotifierProvider(create: (_) => LocaleController()),
    ],
    child: MaterialApp(
      theme: buildLookUpTheme(Brightness.light),
      home: PerfilPage(showBack: showBack),
    ),
  );
}

void main() {
  test('theme uses Helvetica and one transition language on every platform',
      () {
    final theme = buildLookUpTheme(Brightness.light);

    expect(theme.textTheme.bodyMedium?.fontFamily, 'Helvetica');
    expect(
      theme.textTheme.bodyMedium?.fontFamilyFallback,
      containsAll(<String>['Arial', 'sans-serif']),
    );
    expect(
      theme.pageTransitionsTheme.builders.keys,
      containsAll(TargetPlatform.values),
    );
  });

  testWidgets('desktop login uses one centered form without a side panel', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(1440, 900));

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido a LookUp'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Portal de empresas'), findsNothing);
    expect(find.byType(BrandMark), findsOneWidget);
    expect(
      tester.getCenter(find.text('Bienvenido a LookUp')).dx,
      closeTo(720, 1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('registration is a plain form with a normal login link', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(360, 800));

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Regístrate'));
    await tester.pumpAndSettle();

    expect(find.text('Crear cuenta de empresa'), findsOneWidget);
    expect(find.text('Empieza a publicar vacantes'), findsNothing);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(BrandMark), findsOneWidget);
    expect(find.byType(InlinePromptLink), findsOneWidget);
    expect(find.text('Inicia sesión'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    expect(find.text('Publicar vacante'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Vacantes'));
    await tester.pumpAndSettle();

    expect(find.text('Publicar vacante'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('desktop messages use one compact panel without a second title', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(1440, 900));

    await tester.pumpWidget(_testShell());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byTooltip('Mensajes'));
    await tester.pumpAndSettle();

    final panel = find.byKey(const ValueKey('desktop-message-list-panel'));
    expect(panel, findsOneWidget);
    expect(tester.getSize(panel).width, 360);
    expect(find.text('Mensajes'), findsNothing);
    expect(find.text('Buscar conversaciones'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('message route keeps back navigation from 860 to 919px', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(880, 800));

    await tester.pumpWidget(_testShell());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byTooltip('Mensajes'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('desktop-message-list-panel')),
      findsOneWidget,
    );
    expect(find.text('Mensajes'), findsOneWidget);
    expect(find.byTooltip('Volver'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Inicio'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('desktop shell orders messages, alerts and profile at 1440px', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(1440, 900));

    await tester.pumpWidget(_testShell());
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      tester.getSize(find.byKey(const ValueKey('desktop-company-navbar'))),
      const Size(1440, 64),
    );
    final sectionSwitcher = tester.widget<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    );
    expect(sectionSwitcher.duration, const Duration(milliseconds: 180));

    final messageX = tester.getCenter(find.byTooltip('Mensajes')).dx;
    final notificationX = tester.getCenter(find.byTooltip('Notificaciones')).dx;
    final profileX = tester.getCenter(find.byType(InitialsAvatar)).dx;

    expect(find.text('LookUp'), findsNothing);
    expect(messageX, lessThan(notificationX));
    expect(notificationX, lessThan(profileX));
    expect(find.text('Publicar vacante'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Vacantes'));
    await tester.pumpAndSettle();

    expect(find.text('Vacantes'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('publish-vacancy-button')), findsOneWidget);
    expect(find.text('Publicar vacante'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final nestedNavigator = tester.state<NavigatorState>(
      find.byType(Navigator).last,
    );
    nestedNavigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Detalle temporal')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Detalle temporal'), findsOneWidget);

    await tester.tap(find.text('Vacantes').first);
    await tester.pumpAndSettle();
    expect(find.text('Detalle temporal'), findsNothing);
    expect(
      find.byKey(const ValueKey('publish-vacancy-button')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('mobile vacancy form exposes only the four contract types', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(360, 800));

    await tester.pumpWidget(_vacancyFormShell());
    await tester.pumpAndSettle();

    final contractField = find.byKey(
      const ValueKey('vacancy-contract-field'),
    );
    await tester.ensureVisible(contractField);
    await tester.tap(contractField);
    await tester.pumpAndSettle();

    expect(find.text('Jornada Completa'), findsOneWidget);
    expect(find.text('Jornada Parcial'), findsOneWidget);
    expect(find.text('Prácticas Preprofesionales'), findsOneWidget);
    expect(find.text('Temporal'), findsOneWidget);
    expect(find.text('Freelance'), findsNothing);
    expect(find.text('Tiempo completo'), findsNothing);
    expect(find.text('Medio tiempo'), findsNothing);
    expect(find.text('Prácticas'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop company profile aligns data and saves phone and city', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(1440, 900));
    final profileService = _FakeProfileService();

    await tester.pumpWidget(_profileShell(profileService));
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsNothing);
    expect(
      find.byKey(const ValueKey('company-change-logo-action')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('company-edit-profile-action')),
      findsOneWidget,
    );
    expect(find.text('Editar perfil'), findsNothing);
    expect(find.byTooltip('Editar perfil'), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
    expect(find.byType(Scrollbar), findsNothing);
    expect(find.text('Empresa Prueba'), findsOneWidget);
    expect(find.text(' Empresa Prueba '), findsNothing);
    expect(find.text(' Lima '), findsNothing);
    expect(find.text('empresa@lookup.test'), findsNWidgets(2));
    expect(find.text(' empresa@lookup.test '), findsNothing);
    final emailX = tester
        .getTopLeft(
          find.descendant(
            of: find.byKey(const ValueKey('company-email-row')),
            matching: find.text('empresa@lookup.test'),
          ),
        )
        .dx;
    final phoneX = tester
        .getTopLeft(
          find.descendant(
            of: find.byKey(const ValueKey('company-phone-row')),
            matching: find.text('+51 999 888 777'),
          ),
        )
        .dx;
    final cityX = tester
        .getTopLeft(
          find.descendant(
            of: find.byKey(const ValueKey('company-city-row')),
            matching: find.text('Lima'),
          ),
        )
        .dx;
    final emailLabelRight = tester
        .getTopRight(
          find.descendant(
            of: find.byKey(const ValueKey('company-email-row')),
            matching: find.text('Correo electrónico'),
          ),
        )
        .dx;
    expect(phoneX, closeTo(emailX, 1));
    expect(cityX, closeTo(emailX, 1));
    expect(emailX - emailLabelRight, lessThan(100));

    await tester.tap(find.byTooltip('Editar perfil'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('company-phone-field')),
      '+51 987 654 321',
    );
    await tester.enterText(
      find.byKey(const ValueKey('company-city-field')),
      'Arequipa',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(profileService.lastUpdates?['telefono'], '+51 987 654 321');
    expect(profileService.lastUpdates?['ciudad'], 'Arequipa');
    expect(find.text('+51 987 654 321'), findsOneWidget);
    expect(find.text('Arequipa'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile profile keeps route context and grouped edit actions', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(360, 800));

    await tester.pumpWidget(
      _profileShell(_FakeProfileService(), showBack: true),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Perfil de empresa'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('company-change-logo-action')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('company-edit-profile-action')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
