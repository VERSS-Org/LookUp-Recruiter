import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/services/puesto_service.dart';
import 'package:lookup_flutter/Puesto/views/CrearPuestoPage.dart';
import 'package:lookup_flutter/Puesto/views/DetallePuestoPage.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';

class GestionarOfertas extends StatefulWidget {
  const GestionarOfertas({super.key});

  @override
  State<GestionarOfertas> createState() => _GestionarOfertasState();
}

class _GestionarOfertasState extends State<GestionarOfertas> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final empresaId = authService.cuentaId;
    if (empresaId != null) {
      await Provider.of<PuestoService>(context, listen: false)
          .fetchPuestosPorEmpresa(empresaId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion de Ofertas')),
      body: Consumer<PuestoService>(
        builder: (context, puestoService, child) {
          if (puestoService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (puestoService.puestosEmpresa.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 48, 18, 28),
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: softShadow(opacity: 0.12, blur: 26, y: 12),
                      ),
                      child: Image.asset(
                        'assets/images/logo_lookup.png',
                        height: 76,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Aun no has publicado ofertas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800, color: kInk),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Crea tu primer puesto para empezar a recibir postulantes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kInkMuted, height: 1.4),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 88),
              itemCount: puestoService.puestosEmpresa.length,
              itemBuilder: (context, index) {
                final puesto = puestoService.puestosEmpresa[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    leading: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: kSkyBlue.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.work_outline, color: kBrandBlue),
                    ),
                    title: Text(
                      puesto['titulo'] ?? 'Sin titulo',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: kInk),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        puesto['ubicacion'] ?? 'Ubicacion no especificada',
                        style: const TextStyle(color: kInkMuted),
                      ),
                    ),
                    trailing:
                        const Icon(Icons.chevron_right, color: kBrandBlue),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                DetallePuestoPage(puesto: puesto)),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const CrearPuestoPage()),
          );
          if (created == true && mounted) {
            await _refresh();
          }
        },
        label: const Text('Publicar Oferta'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
