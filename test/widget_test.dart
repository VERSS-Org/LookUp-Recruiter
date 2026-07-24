import 'dart:async';

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

class _RetryBootAuthService extends AuthService {
  int attempts = 0;
  final Completer<bool> firstAttempt = Completer<bool>();

  @override
  Future<bool> tryAutoLogin() {
    attempts++;
    if (attempts == 1) return firstAttempt.future;
    return Future.value(false);
  }
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
      ChangeNotifierProvider(create: (_) => ThemeController()),
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
  testWidgets('session bootstrap times out and offers a working retry', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final auth = _RetryBootAuthService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: auth),
          ChangeNotifierProvider(create: (_) => LocaleController()),
        ],
        child: MaterialApp(
          theme: buildLookUpTheme(Brightness.light),
          home: const SessionGate(
            bootTimeout: Duration(milliseconds: 20),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 25));
    await tester.pump();
    expect(find.text('No pudimos conectar con LookUp'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(auth.attempts, 2);
    expect(find.text('Inicia sesión'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('theme uses Sora, Manrope and one transition language everywhere', () {
    final theme = buildLookUpTheme(Brightness.light);

    expect(theme.textTheme.headlineMedium?.fontFamily, 'Sora');
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Manrope');
    expect(
      theme.textTheme.bodyMedium?.fontFamilyFallback,
      containsAll(<String>['Arial', 'sans-serif']),
    );
    expect(
      theme.pageTransitionsTheme.builders.keys,
      containsAll(TargetPlatform.values),
    );
  });

  testWidgets('desktop login uses the branded split layout', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(1440, 900));

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Inicia sesión'), findsOneWidget);
    expect(find.text('El talento adecuado,\nsin vueltas.'), findsOneWidget);
    expect(find.text('LookUp Empresas'), findsOneWidget);
    expect(find.byType(BrandMark), findsOneWidget);
    expect(tester.getCenter(find.text('Inicia sesión')).dx, greaterThan(720));
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
    expect(
      tester
          .widget<Icon>(
            find.byKey(const ValueKey('password-strength-icon')),
          )
          .icon,
      Icons.info_outline_rounded,
    );
    await tester.enterText(
      find.byKey(const ValueKey('company-register-password-field')),
      'Segura123!',
    );
    await tester.pump();
    expect(
      tester
          .widget<Icon>(
            find.byKey(const ValueKey('password-strength-icon')),
          )
          .icon,
      Icons.check_circle,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile shell keeps core navigation visible at the bottom', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(360, 800));

    await tester.pumpWidget(_testShell());
    await tester.pump(const Duration(milliseconds: 100));

    final notificationX = tester.getCenter(find.byTooltip('Notificaciones')).dx;
    final profileX = tester.getCenter(find.byType(InitialsAvatar)).dx;

    expect(notificationX, lessThan(profileX));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Vacantes'), findsWidgets);
    expect(find.text('Mensajes'), findsOneWidget);
    expect(find.text('Perfil de empresa'), findsOneWidget);
    expect(find.text('Publicar vacante'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Vacantes'));
    await tester.pumpAndSettle();

    expect(find.text('Publicar vacante'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('desktop messages use one compact contextual sidebar', (
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
    expect(tester.getSize(panel).width, 300);
    expect(find.text('Mensajes'), findsOneWidget);
    expect(find.text('Buscar conversaciones'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('messages keep the mobile bottom navigation below 960px', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(880, 800));

    await tester.pumpWidget(_testShell());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Mensajes'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('mobile-company-messages-list')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('desktop-message-list-panel')),
      findsNothing,
    );
    expect(find.text('Mensajes'), findsNWidgets(2));
    expect(find.byType(BrandMark), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Inicio'));
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
      const Size(1440, 52),
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

    expect(find.text('Vacantes'), findsWidgets);
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
    expect(find.text('Vacantes'), findsWidgets);
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
    expect(find.text('Cerrar sesión'), findsNothing);
    expect(find.text('Editar perfil'), findsNothing);
    expect(find.byTooltip('Editar perfil'), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
    expect(find.byType(Scrollbar), findsNothing);
    expect(find.text('Empresa Prueba'), findsOneWidget);
    expect(find.text(' Empresa Prueba '), findsNothing);
    expect(find.text(' Lima '), findsNothing);
    expect(find.text('empresa@lookup.test'), findsOneWidget);
    expect(find.text(' empresa@lookup.test '), findsNothing);
    expect(find.byKey(const ValueKey('company-email-row')), findsNothing);
    final profileScroll = find.byKey(const ValueKey('company-profile-scroll'));
    expect(tester.getSize(profileScroll).width, closeTo(1440, 1));
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
    expect(phoneX, closeTo(cityX, 1));

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
    expect(find.text('Cerrar sesión'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
