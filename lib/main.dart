import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/services/profile_service.dart';
import 'package:lookup_flutter/services/postulacion_service.dart';
import 'package:lookup_flutter/services/metricas_service.dart';
import 'package:lookup_flutter/services/puesto_service.dart';
import 'package:lookup_flutter/services/contacto_service.dart';
import 'package:lookup_flutter/Auth/views/Login.dart';
import 'package:lookup_flutter/Auth/views/Registro.dart';
import 'package:lookup_flutter/Auth/views/RecuperarContrasenia.dart';
import 'package:lookup_flutter/BarraNavegacion.dart';
import 'package:lookup_flutter/Puesto/views/GestionarOfertas.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => ProfileService()),
        ChangeNotifierProvider(create: (context) => PostulacionService()),
        ChangeNotifierProvider(create: (context) => MetricasService()),
        ChangeNotifierProvider(create: (context) => PuestoService()),
        ChangeNotifierProvider(create: (context) => ContactoService()),
      ],
      child: Consumer<AuthService>(
        builder: (context, authService, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'LookUp',
            theme: buildLookUpTheme(),
            home: const SessionGate(),
            // Define las rutas nombradas de la aplicación
            routes: {
              '/home': (context) => const BarraNavegacion(),
              '/login': (context) => const Login(),
              '/registro': (context) => const Registro(),
              '/recuperar': (context) => const RecuperarContrasenia(),
              '/ofertas': (context) => const GestionarOfertas(),
            },
          );
        },
      ),
    );
  }
}

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
      await authService.logout();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }
        return snapshot.data == true ? const BarraNavegacion() : const Login();
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kBrandGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Image.asset('assets/images/logo_lookup.png', width: 140),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
