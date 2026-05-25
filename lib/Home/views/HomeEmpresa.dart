import 'package:flutter/material.dart';
import 'package:lookup_flutter/HomeAdmin/HomeAdmin.dart';

class HomeEmpresa extends StatelessWidget {
  final VoidCallback onNavigateToProfile;
  final VoidCallback onNavigateToOfertas;

  const HomeEmpresa({super.key, required this.onNavigateToProfile, required this.onNavigateToOfertas});

  @override
  Widget build(BuildContext context) {
    return HomeAdmin(onNavigateToProfile: onNavigateToProfile, onNavigateToOfertas: onNavigateToOfertas);
  }
}
