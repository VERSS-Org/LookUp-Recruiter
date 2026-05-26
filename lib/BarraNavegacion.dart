import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/Home.dart';
import 'package:lookup_flutter/Postulacion/views/PostulacionPage.dart';
import 'package:lookup_flutter/Postulacion/views/MisPostulacionesPage.dart';
import 'package:lookup_flutter/Perfil/views/PerfilPage.dart';
import 'package:lookup_flutter/Puesto/views/GestionarOfertas.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';

class BarraNavegacion extends StatefulWidget {
  const BarraNavegacion({super.key});

  @override
  State<BarraNavegacion> createState() => _BarraNavegacionState();
}

class _BarraNavegacionState extends State<BarraNavegacion> {
  int _currentIndex = 0;

  void _navigateTo(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isPostulante = authService.role == 'postulante';

    // Construir screens basado en el rol
    final List<Widget> screens = [
      HomePage(
        onNavigateToPostulaciones: () => _navigateTo(isPostulante ? 2 : 1),
        onNavigateToProfile: () => _navigateTo(isPostulante ? 3 : 2),
        onNavigateToOfertas: () => _navigateTo(1),
      ),
      if (isPostulante) const PostulacionPage(), // Solo para candidatos
      if (!isPostulante) const GestionarOfertas(), // Solo para empresas
      if (isPostulante) const MisPostulacionesPage(), // Solo para candidatos
      const PerfilPage(),
    ];

    // Construir items de navegación basado en el rol
    final List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined), label: 'Inicio'),
      if (isPostulante)
        const BottomNavigationBarItem(
            icon: Icon(Icons.work_outline), label: 'Ofertas'),
      if (!isPostulante)
        const BottomNavigationBarItem(
            icon: Icon(Icons.work_outline), label: 'Ofertas'),
      if (isPostulante)
        const BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined), label: 'Mis Postulaciones'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline), label: 'Perfil'),
    ];

    // Validar que currentIndex esté dentro del rango válido
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _navigateTo,
        indicatorColor: kBrandBlue.withOpacity(0.12),
        destinations: items.map((item) {
          return NavigationDestination(
            icon: IconTheme(
              data: const IconThemeData(color: kInk),
              child: item.icon,
            ),
            selectedIcon: IconTheme(
              data: const IconThemeData(color: kBrandBlue),
              child: item.icon,
            ),
            label: item.label ?? '',
          );
        }).toList(),
      ),
    );
  }
}
