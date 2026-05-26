import 'package:flutter/material.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';

class HomePostulante extends StatelessWidget {
  final VoidCallback onNavigateToPostulaciones;

  const HomePostulante({super.key, required this.onNavigateToPostulaciones});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cabecera de bienvenida
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: kBrandGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: softShadow(opacity: 0.30, blur: 28, y: 14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bienvenido, Postulante',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Gestiona tu busqueda laboral en un solo lugar.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.88)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _buildQuickAccess(
            'Ver mis postulaciones',
            Icons.work_outline,
            onTap: onNavigateToPostulaciones,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess(String text, IconData icon,
      {required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 8,
      shadowColor: kBrandBlue.withValues(alpha: 0.10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kBrandBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: kBrandBlue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kInk,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: kInkMuted.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
