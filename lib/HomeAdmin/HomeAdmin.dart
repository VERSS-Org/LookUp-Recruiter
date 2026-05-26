import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/services/puesto_service.dart';
import 'package:lookup_flutter/Puesto/views/CrearPuestoPage.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';

class HomeAdmin extends StatefulWidget {
  final VoidCallback onNavigateToProfile;
  final VoidCallback onNavigateToOfertas;

  const HomeAdmin(
      {super.key,
      required this.onNavigateToProfile,
      required this.onNavigateToOfertas});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  String _adminName = '...';
  int? _ofertasActivasCount;
  int? _ofertasCerradasCount;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final puestoService = Provider.of<PuestoService>(context, listen: false);

    // Obtener información de la cuenta
    final cuentaInfo = await authService.getCuentaInfo();
    if (mounted && cuentaInfo != null) {
      setState(() {
        _adminName = cuentaInfo['nombre_completo'] ?? '...';
      });

      // Usar el ID de la cuenta como ID de la empresa para obtener las ofertas
      final cuentaId = authService.cuentaId;
      if (cuentaId != null) {
        // Cargar ambas métricas en paralelo
        final results = await Future.wait([
          puestoService.getNumeroOfertasActivas(cuentaId),
          puestoService.getNumeroOfertasCerradas(cuentaId),
        ]);

        if (mounted) {
          setState(() {
            _ofertasActivasCount = results[0];
            _ofertasCerradasCount = results[1];
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _ofertasActivasCount = 0;
            _ofertasCerradasCount = 0;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _ofertasActivasCount = 0;
          _ofertasCerradasCount = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio del Administrador'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: kBrandGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: softShadow(opacity: 0.30, blur: 28, y: 14),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(Icons.business, color: Colors.white),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Hola, $_adminName!',
                        style: const TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Panel de gestion de tu empresa',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),

          // Stats cards
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Ofertas activas',
                    value: _ofertasActivasCount?.toString() ?? '...',
                    icon: Icons.work_outline,
                    color: kBrandBlue,
                  ),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: _StatCard(
                    label: 'Ofertas Cerradas',
                    value: _ofertasCerradasCount?.toString() ?? '...',
                    icon: Icons.check_circle_outline,
                    color: kSkyBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28.0),

          // Quick actions
          const Text(
            'Acceso Rápido',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w800,
              color: kInk,
            ),
          ),
          const SizedBox(height: 14.0),
          _QuickAction(
            icon: Icons.work,
            color: kBrandBlue,
            title: 'Gestionar Ofertas',
            onTap: widget.onNavigateToOfertas,
          ),
          const SizedBox(height: 12),
          _QuickAction(
            icon: Icons.add_circle,
            color: kSkyBlue,
            title: 'Crear Nueva Oferta',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CrearPuestoPage()),
              );
            },
          ),
          const SizedBox(height: 12),
          _QuickAction(
            icon: Icons.business,
            color: kBrandBlue,
            title: 'Perfil de Empresa',
            onTap: widget.onNavigateToProfile,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: kInk,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: kInkMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 8,
      shadowColor: kBrandBlue.withValues(alpha: 0.10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
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
