import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/services/profile_service.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/services/puesto_service.dart';
import 'package:lookup_flutter/Puesto/views/CrearPuestoPage.dart';
import 'package:lookup_flutter/Puesto/views/DetallePuestoPage.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';
import 'package:lookup_flutter/theme/lookup_widgets.dart';

/// Panel de inicio para cuentas de empresa: resumen operativo de vacantes.
class HomeEmpresa extends StatefulWidget {
  final VoidCallback onNavigateToOfertas;
  final VoidCallback onNavigateToProfile;

  const HomeEmpresa({
    super.key,
    required this.onNavigateToOfertas,
    required this.onNavigateToProfile,
  });

  @override
  State<HomeEmpresa> createState() => _HomeEmpresaState();
}

class _HomeEmpresaState extends State<HomeEmpresa> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  Future<void> _loadInitialData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final empresaId = authService.cuentaId;
    if (empresaId == null) return;

    await Future.wait([
      Provider.of<ProfileService>(context, listen: false)
          .fetchProfile(empresaId),
      Provider.of<PuestoService>(context, listen: false)
          .fetchPuestosPorEmpresa(empresaId),
    ]);
  }

  Future<void> _crearVacante() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CrearPuestoPage()),
    );
    if (created == true && mounted) {
      await _loadInitialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final profile = context.watch<ProfileService>().profileData ??
        const <String, dynamic>{};
    final puestoService = context.watch<PuestoService>();
    final puestos = puestoService.puestosEmpresa;
    final abiertas =
        puestos.where((p) => p['estado']?.toString() == 'abierto').length;
    final cerradas =
        puestos.where((p) => p['estado']?.toString() == 'cerrado').length;
    final nombre = profile['nombre_completo']?.toString() ?? 'Empresa';
    final ordenados = List<dynamic>.from(puestos)
      ..sort((a, b) {
        final aDate = DateTime.tryParse(
          a['fecha_publicacion']?.toString() ?? '',
        );
        final bDate = DateTime.tryParse(
          b['fecha_publicacion']?.toString() ?? '',
        );
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
    final recientes = ordenados.take(4).toList();
    final isLoading = puestoService.isLoading && puestos.isEmpty;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: PageContainer(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.sizeOf(context).width < 480 ? 16 : 22,
              26,
              MediaQuery.sizeOf(context).width < 480 ? 16 : 22,
              32,
            ),
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 620;
                  final heading = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${context.t('home.greeting')} $nombre',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.t('home.subtitle'),
                        style: TextStyle(color: c.inkMuted, fontSize: 14.5),
                      ),
                    ],
                  );
                  final action = FilledButton.icon(
                    onPressed: _crearVacante,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(context.t('home.publish')),
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        heading,
                        const SizedBox(height: 16),
                        action,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: heading),
                      const SizedBox(width: 20),
                      action,
                    ],
                  );
                },
              ),
              const SizedBox(height: 22),
              _StatStrip(
                items: [
                  (
                    label: context.t('home.open'),
                    value: isLoading ? '…' : '$abiertas',
                    color: c.success,
                  ),
                  (
                    label: context.t('home.closed'),
                    value: isLoading ? '…' : '$cerradas',
                    color: c.inkFaint,
                  ),
                  (
                    label: context.t('home.total'),
                    value: isLoading ? '…' : '${puestos.length}',
                    color: c.brand,
                  ),
                ],
              ),
              if (puestoService.errorMessage != null && puestos.isNotEmpty) ...[
                const SizedBox(height: 16),
                ErrorBanner(
                  message: context.t('jobs.load.error'),
                  actionLabel: context.t('common.retry'),
                  onAction: _loadInitialData,
                ),
              ],
              const SizedBox(height: 26),
              SectionLabel(
                title: context.t('home.recent'),
                actionLabel: context.t('home.see_all'),
                onAction: widget.onNavigateToOfertas,
              ),
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (puestoService.errorMessage != null && puestos.isEmpty)
                ErrorBanner(
                  message: context.t('jobs.load.error'),
                  actionLabel: context.t('common.retry'),
                  onAction: _loadInitialData,
                )
              else if (recientes.isEmpty)
                EmptyState(
                  icon: Icons.work_off_outlined,
                  title: context.t('home.empty.title'),
                  message: context.t('home.empty.msg'),
                  actionLabel: context.t('home.publish'),
                  onAction: _crearVacante,
                )
              else
                ...recientes.map(
                  (puesto) => _RecentOfferTile(
                    puesto: puesto,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetallePuestoPage(
                            puesto: Map<String, dynamic>.from(puesto),
                          ),
                        ),
                      ).then((_) => _loadInitialData());
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Franja de métricas plana: valores y etiquetas separados por líneas, sin
/// tarjetas ni contenedores (evita el exceso de "cards").
class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.items});

  final List<({String label, String value, Color color})> items;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.border),
          bottom: BorderSide(color: c.border),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Container(width: 1, height: 34, color: c.border),
            Expanded(
              child: Column(
                children: [
                  Text(
                    items[i].value,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: items[i].color,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i].label,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.inkMuted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecentOfferTile extends StatelessWidget {
  const _RecentOfferTile({required this.puesto, required this.onTap});

  final dynamic puesto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final titulo = puesto['titulo']?.toString() ?? 'Sin título';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            InitialsAvatar(
              name: titulo,
              size: 42,
              fallbackIcon: Icons.work_outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    puesto['ubicacion']?.toString() ??
                        'Ubicación no especificada',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.inkMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            StatusChip(
              label: puesto['estado']?.toString() ?? 'abierto',
              compact: true,
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 20, color: c.inkFaint),
          ],
        ),
      ),
    );
  }
}
