import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/Home/views/HomePostulante.dart';
import 'package:lookup_flutter/Home/views/HomeEmpresa.dart';

class HomePage extends StatelessWidget {
  final VoidCallback onNavigateToPostulaciones;
  final VoidCallback onNavigateToProfile;
  final VoidCallback onNavigateToOfertas;

  const HomePage({
    super.key,
    required this.onNavigateToPostulaciones,
    required this.onNavigateToProfile,
    required this.onNavigateToOfertas,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (authService.role == 'postulante') {
      return HomePostulante(onNavigateToPostulaciones: onNavigateToPostulaciones);
    } else if (authService.role == 'empresa') {
      return HomeEmpresa(onNavigateToProfile: onNavigateToProfile, onNavigateToOfertas: onNavigateToOfertas);
    } else {
      // Fallback a una vista genérica o de carga
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
}
