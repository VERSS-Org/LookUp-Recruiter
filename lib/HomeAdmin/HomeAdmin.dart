import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/services/puesto_service.dart';
import 'package:lookup_flutter/Puesto/views/CrearPuestoPage.dart';

class HomeAdmin extends StatefulWidget {
  final VoidCallback onNavigateToProfile;
  final VoidCallback onNavigateToOfertas;

  const HomeAdmin({super.key, required this.onNavigateToProfile, required this.onNavigateToOfertas});

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.business),
                ),
                const SizedBox(width: 16.0),
                Text(
                  '¡Hola, $_adminName!',
                  style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 32.0),

            // Stats cards
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Ofertas Totales', textAlign: TextAlign.center),
                            const SizedBox(height: 8.0),
                            Text(
                              _ofertasActivasCount?.toString() ?? '...',
                              style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Ofertas Cerradas', textAlign: TextAlign.center),
                            const SizedBox(height: 8.0),
                            Text(
                              _ofertasCerradasCount?.toString() ?? '...',
                              style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32.0),

            // Quick actions
            const Text(
              'Acceso Rápido',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            ListTile(
              leading: const Icon(Icons.work),
              title: const Text('Gestionar Ofertas'),
              trailing: const Icon(Icons.chevron_right),
              onTap: widget.onNavigateToOfertas,
            ),
            ListTile(
              leading: const Icon(Icons.add_circle),
              title: const Text('Crear Nueva Oferta'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CrearPuestoPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Perfil de Empresa'),
              trailing: const Icon(Icons.chevron_right),
              onTap: widget.onNavigateToProfile,
            ),
          ],
        ),
      ),
    );
  }
}
