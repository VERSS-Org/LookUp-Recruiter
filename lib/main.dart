import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/services/profile_service.dart';
import 'package:lookup_flutter/services/postulacion_service.dart';
import 'package:lookup_flutter/services/puesto_service.dart';
import 'package:lookup_flutter/services/contacto_service.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/services/theme_controller.dart';
import 'package:lookup_flutter/Auth/views/Login.dart';
import 'package:lookup_flutter/Auth/views/Registro.dart';
import 'package:lookup_flutter/Auth/views/RecuperarContrasenia.dart';
import 'package:lookup_flutter/BarraNavegacion.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ThemeController _themeController;
  late final LocaleController _localeController;
  late final ProfileService _profileService;
  late final PostulacionService _postulacionService;
  late final PuestoService _puestoService;
  late final ContactoService _contactoService;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _themeController = ThemeController();
    _localeController = LocaleController();
    _profileService = ProfileService();
    _postulacionService = PostulacionService();
    _puestoService = PuestoService();
    _contactoService = ContactoService();
    _authService = AuthService(onSessionCleared: _clearSessionData);
  }

  void _clearSessionData() {
    _profileService.clearData();
    _postulacionService.clearData();
    _puestoService.clearData();
    _contactoService.clearData();
  }

  @override
  void dispose() {
    _authService.dispose();
    _profileService.dispose();
    _postulacionService.dispose();
    _puestoService.dispose();
    _contactoService.dispose();
    _localeController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _themeController),
        ChangeNotifierProvider.value(value: _localeController),
        ChangeNotifierProvider.value(value: _authService),
        ChangeNotifierProvider.value(value: _profileService),
        ChangeNotifierProvider.value(value: _postulacionService),
        ChangeNotifierProvider.value(value: _puestoService),
        ChangeNotifierProvider.value(value: _contactoService),
      ],
      child: Consumer2<ThemeController, LocaleController>(
        builder: (context, themeController, localeController, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'LookUp Empresas',
            theme: buildLookUpTheme(Brightness.light),
            darkTheme: buildLookUpTheme(Brightness.dark),
            themeMode: themeController.mode,
            home: const SessionGate(),
            routes: {
              '/home': (context) => const AuthenticatedShell(),
              '/login': (context) => const Login(),
              '/registro': (context) => const Registro(),
              '/recuperar': (context) => const RecuperarContrasenia(),
            },
          );
        },
      ),
    );
  }
}

/// Restaura la sesion guardada y decide entre login y el shell de empresa.
class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final Future<bool> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = _restoreSession();
  }

  Future<bool> _restoreSession() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final restored = await authService.tryAutoLogin();
    if (!restored) return false;
    if (authService.role != 'empresa') {
      // Esta app es solo para cuentas de empresa.
      await authService.logout();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthService>().isAuthenticated;
    return FutureBuilder<bool>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }
        return snapshot.data == true && isAuthenticated
            ? const BarraNavegacion()
            : const Login();
      },
    );
  }
}

/// Evita dejar visible el shell si la sesión expira durante el uso.
class AuthenticatedShell extends StatelessWidget {
  const AuthenticatedShell({super.key});

  @override
  Widget build(BuildContext context) {
    return context.watch<AuthService>().isAuthenticated
        ? const BarraNavegacion()
        : const Login();
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo_lookup.png', width: 150),
            const SizedBox(height: 30),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: c.brand,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.t('app.tagline'),
              style: TextStyle(color: c.inkMuted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
