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
            // Define la pantalla de arranque
            home: const Login(), 
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
