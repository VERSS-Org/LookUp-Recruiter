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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Consumer<PuestoService>(
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
                            borderRadius: BorderRadius.circular(24),
                            boxShadow:
                                softShadow(opacity: 0.12, blur: 26, y: 12),
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
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: kInk),
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 760;
                    final itemWidth = isWide
                        ? (constraints.maxWidth - 48) / 2
                        : constraints.maxWidth - 36;
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 88),
                      children: [
                        SectionLabel(
                          title:
                              'Tus ofertas (${puestoService.puestosEmpresa.length})',
                        ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: puestoService.puestosEmpresa.map((puesto) {
                            return SizedBox(
                              width: itemWidth,
                              child: _OfferCard(
                                puesto: puesto,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DetallePuestoPage(puesto: puesto),
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
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

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.puesto, required this.onTap});

  final dynamic puesto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final estado = puesto['estado']?.toString() ?? 'abierto';
    final isOpen = estado == 'abierto';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: kSkyBlue.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.work_outline, color: kBrandBlue),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isOpen ? Colors.green : Colors.blueGrey)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isOpen ? 'ABIERTA' : 'CERRADA',
                      style: TextStyle(
                        color: isOpen ? Colors.green.shade700 : Colors.blueGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                puesto['titulo'] ?? 'Sin titulo',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: kInk,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                puesto['ubicacion'] ?? 'Ubicacion no especificada',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: kInkMuted),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.group_outlined,
                    color: kBrandBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Ver detalle y candidatos',
                      style: TextStyle(
                        color: kBrandBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: kInkMuted.withValues(alpha: 0.7),
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
