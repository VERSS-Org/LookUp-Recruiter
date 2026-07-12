import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lookup_flutter/Auth/views/Login.dart';
import 'package:lookup_flutter/BarraNavegacion.dart';
import 'package:lookup_flutter/Perfil/views/CandidatoPerfilPage.dart';
import 'package:lookup_flutter/Puesto/views/PuestoCandidatosPage.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/services/contacto_service.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/services/postulacion_service.dart';
import 'package:lookup_flutter/services/profile_service.dart';
import 'package:lookup_flutter/services/puesto_service.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _CandidatePostulacionService extends PostulacionService {
  final List<dynamic> _items = [
    {
      'postulacion_id': 'post-1',
      'estado': 'pendiente',
      'fecha_postulacion': '2026-07-12T10:00:00Z',
      'candidato': {
        'cuenta_id': 'candidate-1',
        'nombre_completo': 'Luis Rodríguez',
        'carrera': 'Ingeniería de software',
        'ciudad': 'Lima',
      },
    },
  ];

  @override
  List<dynamic> get postulacionesPuesto => _items;

  @override
  Future<void> fetchPostulacionesPorPuesto(String puestoId) async {}
}

class _ShellPostulacionService extends PostulacionService {
  @override
  Future<void> fetchEventos({bool notify = true}) async {}

  @override
  Future<void> markEventosSeen() async {}
}

class _ContactoService extends ContactoService {
  @override
  Future<void> fetchBandeja({bool notify = true}) async {}
}

Widget _candidateListShell() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<PostulacionService>(
        create: (_) => _CandidatePostulacionService(),
      ),
      ChangeNotifierProvider(create: (_) => LocaleController()),
    ],
    child: MaterialApp(
      theme: buildLookUpTheme(Brightness.light),
      home: Scaffold(
        body: CandidatosView(
          puesto: const {'puesto_id': 'puesto-1', 'titulo': 'Backend'},
        ),
      ),
    ),
  );
}

Widget _navigationShell() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthService()),
      ChangeNotifierProvider(create: (_) => ProfileService()),
      ChangeNotifierProvider(create: (_) => PuestoService()),
      ChangeNotifierProvider<PostulacionService>(
        create: (_) => _ShellPostulacionService(),
      ),
      ChangeNotifierProvider<ContactoService>(
        create: (_) => _ContactoService(),
      ),
      ChangeNotifierProvider(create: (_) => LocaleController()),
    ],
    child: MaterialApp(
      theme: buildLookUpTheme(Brightness.light),
      home: const BarraNavegacion(),
    ),
  );
}

Map<String, dynamic> _longCandidateProfile() {
  return {
    'nombre_completo': 'Luis Rodríguez',
    'email': 'luis@lookup.test',
    'carrera': 'Ingeniería de software',
    'ciudad': 'Lima',
    'perfil': {
      'experiencia': [
        for (var index = 0; index < 18; index++)
          {
            'puesto': 'Experiencia $index',
            'organizacion': 'Empresa $index',
            'periodo': '2024 - 2025',
          },
      ],
    },
  };
}

Widget _profileShell() {
  return ChangeNotifierProvider(
    create: (_) => LocaleController(),
    child: MaterialApp(
      theme: buildLookUpTheme(Brightness.light),
      home: CandidatoPerfilPage(
        cuentaId: 'candidate-1',
        profileLoader: (_) async => _longCandidateProfile(),
      ),
    ),
  );
}

void main() {
  testWidgets('company login directs applicants to their own portal', (
    tester,
  ) async {
    _setViewport(tester, const Size(1440, 900));
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LocaleController(),
        child: MaterialApp(
          theme: buildLookUpTheme(Brightness.light),
          home: const Login(),
        ),
      ),
    );

    expect(find.text('¿Eres postulante?'), findsOneWidget);
    expect(find.text('Ir al portal de postulantes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('candidate filters use exact status names and compact menu', (
    tester,
  ) async {
    _setViewport(tester, const Size(1440, 900));
    await tester.pumpWidget(_candidateListShell());
    await tester.pumpAndSettle();

    for (final label in [
      'Todos',
      'Pendiente',
      'En revisión',
      'Entrevista',
      'Aceptado',
      'Rechazado',
    ]) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('En proceso'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('candidate-status-menu')));
    await tester.pumpAndSettle();

    final items = find.byWidgetPredicate(
      (widget) => widget is PopupMenuItem<String>,
    );
    expect(items, findsNWidgets(5));
    expect(tester.getSize(items.first).width, lessThanOrEqualTo(240));
    expect(tester.takeException(), isNull);
  });

  testWidgets('candidate status controls remain usable at 360px', (
    tester,
  ) async {
    _setViewport(tester, const Size(360, 800));
    await tester.pumpWidget(_candidateListShell());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('candidate-status-trigger')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('notifications are anchored popup on desktop', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(1440, 900));
    await tester.pumpWidget(_navigationShell());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Notificaciones'));
    await tester.pumpAndSettle();

    final popup = find.byKey(
      const ValueKey('desktop-notifications-popup'),
    );
    expect(popup, findsOneWidget);
    expect(tester.getSize(popup), const Size(420, 480));
    expect(tester.getTopRight(popup).dx, lessThanOrEqualTo(1440));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(popup, findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('notifications remain a full page on mobile', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(360, 800));
    await tester.pumpWidget(_navigationShell());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Notificaciones'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('mobile-notifications-page')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('desktop-notifications-popup')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('candidate profile scroll owns the full desktop viewport', (
    tester,
  ) async {
    _setViewport(tester, const Size(1440, 900));
    await tester.pumpWidget(_profileShell());
    await tester.pumpAndSettle();

    final scroll = find.byKey(
      const ValueKey('candidate-profile-page-scroll'),
    );
    expect(scroll, findsOneWidget);
    expect(tester.getTopRight(scroll).dx, closeTo(1440, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('candidate profile remains responsive at 360px', (tester) async {
    _setViewport(tester, const Size(360, 800));
    await tester.pumpWidget(_profileShell());
    await tester.pumpAndSettle();

    final scroll = find.byKey(
      const ValueKey('candidate-profile-page-scroll'),
    );
    expect(tester.getSize(scroll).width, closeTo(360, 1));
    expect(tester.takeException(), isNull);
  });
}
