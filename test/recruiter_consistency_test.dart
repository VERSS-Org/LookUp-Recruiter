import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lookup_flutter/Auth/views/Login.dart';
import 'package:lookup_flutter/BarraNavegacion.dart';
import 'package:lookup_flutter/Contacto/views/MensajesEmpresa.dart';
import 'package:lookup_flutter/Perfil/views/CandidatoPerfilPage.dart';
import 'package:lookup_flutter/Puesto/views/DetallePuestoPage.dart';
import 'package:lookup_flutter/Puesto/views/GestionarOfertas.dart';
import 'package:lookup_flutter/Puesto/views/PuestoCandidatosPage.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/services/contacto_service.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/services/postulacion_service.dart';
import 'package:lookup_flutter/services/profile_service.dart';
import 'package:lookup_flutter/services/puesto_service.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';
import 'package:lookup_flutter/theme/lookup_widgets.dart';

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

class _ThreadContactoService extends ContactoService {
  final List<dynamic> _threads = [
    {
      'postulacion_id': 'post-1',
      'puesto_titulo': 'Frontend',
      'estado_postulacion': 'pendiente',
      'no_leidos': 1,
      'contraparte': {
        'cuenta_id': 'candidate-1',
        'nombre': 'Ana Torres',
      },
      'ultimo_mensaje': {
        'texto': 'Hola, quisiera conversar.',
        'fecha': '2026-07-12T10:00:00Z',
        'remitente_rol': 'postulante',
      },
    },
  ];

  @override
  List<dynamic> get bandeja => _threads;

  @override
  Future<void> fetchBandeja({bool notify = true}) async {}

  @override
  Future<List<dynamic>> fetchContactos(String postulacionId) async => [];

  @override
  Future<void> marcarLeidos(String postulacionId) async {}
}

class _VacancyAuthService extends AuthService {
  @override
  String? get cuentaId => 'company-1';
}

class _VacancyPuestoService extends PuestoService {
  final List<dynamic> _items = [
    {
      'puesto_id': 'job-1',
      'empresa_id': 'company-1',
      'titulo': 'Frontend',
      'descripcion': 'Construir interfaces accesibles.',
      'ubicacion': 'Lima',
      'tipo_contrato': 'jornada_completa',
      'estado': 'abierto',
      'fecha_publicacion': '2026-07-12T10:00:00Z',
    },
  ];

  @override
  List<dynamic> get puestosEmpresa => _items;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  Future<void> fetchPuestosPorEmpresa(String empresaId) async {}

  @override
  Future<Map<String, dynamic>?> getPuestoDetails(String puestoId) async =>
      Map<String, dynamic>.from(_items.first as Map);
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

Widget _profileShell([Map<String, dynamic>? profile]) {
  return ChangeNotifierProvider(
    create: (_) => LocaleController(),
    child: MaterialApp(
      theme: buildLookUpTheme(Brightness.light),
      home: CandidatoPerfilPage(
        cuentaId: 'candidate-1',
        profileLoader: (_) async => profile ?? _longCandidateProfile(),
      ),
    ),
  );
}

Widget _messagesShell() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
      ChangeNotifierProvider<ContactoService>(
        create: (_) => _ThreadContactoService(),
      ),
      ChangeNotifierProvider(create: (_) => LocaleController()),
    ],
    child: MaterialApp(
      theme: buildLookUpTheme(Brightness.light),
      home: const MensajesEmpresa(showBack: true),
    ),
  );
}

Widget _vacancyListShell() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthService>(create: (_) => _VacancyAuthService()),
      ChangeNotifierProvider<PuestoService>(
        create: (_) => _VacancyPuestoService(),
      ),
      ChangeNotifierProvider(create: (_) => LocaleController()),
    ],
    child: MaterialApp(
      theme: buildLookUpTheme(Brightness.light),
      home: const GestionarOfertas(),
    ),
  );
}

Widget _vacancyDetailShell() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<PuestoService>(
        create: (_) => _VacancyPuestoService(),
      ),
      ChangeNotifierProvider<PostulacionService>(
        create: (_) => _CandidatePostulacionService(),
      ),
      ChangeNotifierProvider(create: (_) => LocaleController()),
    ],
    child: MaterialApp(
      theme: buildLookUpTheme(Brightness.light),
      home: DetallePuestoPage(
        puesto: Map<String, dynamic>.from(
          _VacancyPuestoService().puestosEmpresa.first as Map,
        ),
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

    expect(find.byType(SegmentedButton<String>), findsNothing);
    expect(find.text('En proceso'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('candidate-filter-menu')));
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
    final items = find.byWidgetPredicate(
      (widget) => widget is PopupMenuItem<String>,
    );
    expect(items, findsNWidgets(6));
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
      find.byKey(const ValueKey('candidate-filter-trigger')),
      findsOneWidget,
    );
    expect(find.byType(SegmentedButton<String>), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('vacancy list uses the same compact dropdown filter', (
    tester,
  ) async {
    _setViewport(tester, const Size(1440, 900));
    await tester.pumpWidget(_vacancyListShell());
    await tester.pumpAndSettle();

    expect(find.byType(SegmentedButton<String>), findsNothing);
    expect(
      find.byKey(const ValueKey('vacancy-filter-trigger')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('vacancy-filter-menu')));
    await tester.pumpAndSettle();

    expect(find.text('Todas'), findsWidgets);
    expect(find.text('Abiertas'), findsOneWidget);
    expect(find.text('Cerradas'), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) => widget is PopupMenuItem<String>),
      findsNWidgets(3),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop company navbar matches the applicant visual pattern', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(1440, 900));
    await tester.pumpWidget(_navigationShell());
    await tester.pump(const Duration(milliseconds: 100));

    final navbar = find.byKey(const ValueKey('desktop-company-navbar'));
    expect(tester.getSize(navbar), const Size(1440, 64));
    expect(
      find.descendant(of: navbar, matching: find.byIcon(Icons.home_outlined)),
      findsNothing,
    );
    expect(
      find.descendant(of: navbar, matching: find.byIcon(Icons.work_outline)),
      findsNothing,
    );
    expect(
      find.descendant(of: navbar, matching: find.text('Empresa')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('desktop-company-profile-menu')),
      findsOneWidget,
    );

    final messagesX = tester.getCenter(find.byTooltip('Mensajes')).dx;
    final notificationsX =
        tester.getCenter(find.byTooltip('Notificaciones')).dx;
    final profileX = tester
        .getCenter(find.byKey(const ValueKey('desktop-company-profile-menu')))
        .dx;
    expect(messagesX, lessThan(notificationsX));
    expect(notificationsX, lessThan(profileX));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('compact desktop navbar copies applicant spacing and type', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(1024, 768));
    await tester.pumpWidget(_navigationShell());
    await tester.pump(const Duration(milliseconds: 100));

    final navbar = find.byKey(const ValueKey('desktop-company-navbar'));
    final logo = find.descendant(of: navbar, matching: find.byType(BrandMark));
    final home = find.descendant(of: navbar, matching: find.text('Inicio'));
    final homeText = tester.widget<Text>(home);

    expect(tester.getTopLeft(logo).dx, closeTo(18, 1));
    expect(
      tester.getTopLeft(home).dx - tester.getTopRight(logo).dx,
      closeTo(19, 1),
    );
    expect(homeText.style?.fontSize, 13.5);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('vacancy detail keeps one title and compact desktop actions', (
    tester,
  ) async {
    _setViewport(tester, const Size(1440, 900));
    await tester.pumpWidget(_vacancyDetailShell());
    await tester.pumpAndSettle();

    final appBar = tester.widget<AppBar>(
      find.byKey(const ValueKey('vacancy-detail-appbar')),
    );
    expect(appBar.title, isNull);
    expect(find.text('Frontend'), findsOneWidget);
    expect(find.text('Detalle'), findsOneWidget);

    final edit = find.widgetWithText(OutlinedButton, 'Editar vacante');
    final close = find.widgetWithText(OutlinedButton, 'Cerrar vacante');
    expect(edit, findsOneWidget);
    expect(close, findsOneWidget);
    expect(tester.getSize(edit).width, lessThan(300));
    expect(tester.getSize(close).width, lessThan(300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop messages do not claim an existing inbox is empty', (
    tester,
  ) async {
    _setViewport(tester, const Size(1440, 900));
    await tester.pumpWidget(_messagesShell());
    await tester.pumpAndSettle();

    expect(find.text('Ana Torres'), findsOneWidget);
    final placeholder = find.byKey(const ValueKey('messages-empty-selection'));
    expect(placeholder, findsOneWidget);
    expect(
      find.descendant(
        of: placeholder,
        matching: find.text('Aún no tienes mensajes'),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('message list and chat remain usable at 360px', (tester) async {
    _setViewport(tester, const Size(360, 800));
    await tester.pumpWidget(_messagesShell());
    await tester.pumpAndSettle();

    expect(find.text('Mensajes'), findsNothing);
    expect(find.byType(BrandMark), findsOneWidget);
    final mobileList =
        find.byKey(const ValueKey('mobile-message-list-content'));
    expect(mobileList, findsOneWidget);
    expect(tester.getSize(mobileList).width, closeTo(360, 1));
    expect(find.byKey(const ValueKey('message-search-field')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Ana Torres'));
    await tester.pumpAndSettle();

    expect(find.byType(ChatEmpresaView), findsOneWidget);
    expect(find.byTooltip('Volver'), findsOneWidget);
    expect(find.text('Frontend'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('mobile-company-messages-list')),
      findsOneWidget,
    );
    expect(find.text('Ana Torres'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
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

  testWidgets('candidate profile never reveals a hidden or missing email', (
    tester,
  ) async {
    _setViewport(tester, const Size(1440, 900));
    await tester.pumpWidget(
      _profileShell({
        'nombre_completo': 'Ana Torres',
        'email': 'privado@lookup.test',
        'perfil': {'mostrar_email': false},
      }),
    );
    await tester.pumpAndSettle();

    expect(find.text('privado@lookup.test'), findsNothing);
    expect(find.text('null'), findsNothing);

    await tester.pumpWidget(
      _profileShell({
        'nombre_completo': 'Ana Torres',
        'email': null,
        'perfil': {'mostrar_email': true},
      }),
    );
    await tester.pumpAndSettle();

    expect(find.text('null'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
