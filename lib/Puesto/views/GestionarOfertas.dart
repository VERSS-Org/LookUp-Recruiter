import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/services/puesto_service.dart';
import 'package:lookup_flutter/Puesto/views/CrearPuestoPage.dart';
import 'package:lookup_flutter/Puesto/views/DetallePuestoPage.dart';
import 'package:lookup_flutter/Puesto/views/EditarPuestoPage.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';
import 'package:lookup_flutter/theme/lookup_widgets.dart';

/// Gestión de vacantes: búsqueda, filtro por estado y acciones rápidas.
class GestionarOfertas extends StatefulWidget {
  const GestionarOfertas({super.key});

  @override
  State<GestionarOfertas> createState() => _GestionarOfertasState();
}

class _GestionarOfertasState extends State<GestionarOfertas> {
  final _searchController = TextEditingController();
  String _query = '';
  String _estadoFiltro = 'todas';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final empresaId = authService.cuentaId;
    if (empresaId != null) {
      await Provider.of<PuestoService>(context, listen: false)
          .fetchPuestosPorEmpresa(empresaId);
    }
  }

  Future<void> _crearVacante() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CrearPuestoPage()),
    );
    if (created == true && mounted) {
      await _refresh();
    }
  }

  List<dynamic> _filtrar(List<dynamic> puestos) {
    final resultado = puestos.where((p) {
      final estado = p['estado']?.toString() ?? 'abierto';
      if (_estadoFiltro != 'todas' && estado != _estadoFiltro) return false;
      if (_query.isEmpty) return true;
      final text = '${p['titulo']} ${p['ubicacion']}'.toLowerCase();
      return text.contains(_query.toLowerCase());
    }).toList();
    resultado.sort((a, b) {
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
    return resultado;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final puestoService = context.watch<PuestoService>();
    final puestos = _filtrar(puestoService.puestosEmpresa);
    final isLoading =
        puestoService.isLoading && puestoService.puestosEmpresa.isEmpty;
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('jobs.title')),
        actions: compact
            ? null
            : [
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: FilledButton.icon(
                    onPressed: _crearVacante,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(context.t('home.publish')),
                  ),
                ),
              ],
      ),
      floatingActionButton: compact
          ? FloatingActionButton.extended(
              onPressed: _crearVacante,
              icon: const Icon(Icons.add),
              label: Text(context.t('home.publish')),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: PageContainer(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 22,
              18,
              compact ? 16 : 22,
              compact ? 104 : 32,
            ),
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 620;
                  final search = TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: context.tr('jobs.search'),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: context.tr('common.clear'),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  );
                  final filtro = SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'todas',
                        label: Text(context.t('jobs.all')),
                      ),
                      ButtonSegment(
                        value: 'abierto',
                        label: Text(context.t('jobs.open')),
                      ),
                      ButtonSegment(
                        value: 'cerrado',
                        label: Text(context.t('jobs.closed')),
                      ),
                    ],
                    selected: {_estadoFiltro},
                    onSelectionChanged: (selection) =>
                        setState(() => _estadoFiltro = selection.first),
                  );

                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(child: search),
                        const SizedBox(width: 12),
                        filtro,
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      search,
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: filtro,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              if (puestoService.errorMessage != null &&
                  puestoService.puestosEmpresa.isNotEmpty) ...[
                ErrorBanner(
                  message: context.t('jobs.load.error'),
                  actionLabel: context.t('common.retry'),
                  onAction: _refresh,
                ),
                const SizedBox(height: 4),
              ],
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (puestoService.errorMessage != null &&
                  puestoService.puestosEmpresa.isEmpty)
                ErrorBanner(
                  message: context.t('jobs.load.error'),
                  actionLabel: context.t('common.retry'),
                  onAction: _refresh,
                )
              else if (puestos.isEmpty)
                EmptyState(
                  icon: Icons.work_off_outlined,
                  title: puestoService.puestosEmpresa.isEmpty
                      ? context.t('home.empty.title')
                      : context.t('jobs.filtered.title'),
                  message: puestoService.puestosEmpresa.isEmpty
                      ? context.t('home.empty.msg')
                      : context.t('jobs.filtered.msg'),
                  actionLabel: puestoService.puestosEmpresa.isEmpty
                      ? context.t('home.publish')
                      : null,
                  onAction: puestoService.puestosEmpresa.isEmpty
                      ? _crearVacante
                      : null,
                )
              else ...[
                Text(
                  '${puestos.length} ${puestos.length == 1 ? context.t('jobs.count.one') : context.t('jobs.count')}',
                  style: TextStyle(color: c.inkFaint, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ...puestos.map(
                  (puesto) => _VacancyRow(
                    puesto: puesto,
                    onOpen: () => _abrirDetalle(puesto),
                    onEdit: () => _editar(puesto),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _abrirDetalle(dynamic puesto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DetallePuestoPage(puesto: Map<String, dynamic>.from(puesto)),
      ),
    ).then((_) => _refresh());
  }

  Future<void> _editar(dynamic puesto) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditarPuestoPage(puesto: Map<String, dynamic>.from(puesto)),
      ),
    );
    if (updated == true && mounted) {
      await _refresh();
    }
  }
}

class _VacancyRow extends StatelessWidget {
  const _VacancyRow({
    required this.puesto,
    required this.onOpen,
    required this.onEdit,
  });

  final dynamic puesto;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  String _fecha(BuildContext context) {
    final raw = puesto['fecha_publicacion']?.toString();
    if (raw == null || raw.isEmpty) return '';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw.split('T').first;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final titulo = puesto['titulo']?.toString() ?? 'Sin título';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 620;
        final summary = Row(
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
                    [
                      puesto['ubicacion']?.toString() ?? 'Sin ubicación',
                      if (_fecha(context).isNotEmpty)
                        '${context.t('jobs.published')} ${_fecha(context)}',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.inkMuted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            if (isWide) ...[
              const SizedBox(width: 10),
              StatusChip(
                label: puesto['estado']?.toString() ?? 'abierto',
                compact: true,
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: context.t('jobs.edit'),
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined, size: 20, color: c.inkMuted),
              ),
            ],
            Icon(Icons.chevron_right, size: 20, color: c.inkFaint),
          ],
        );

        return Semantics(
          button: true,
          label: titulo,
          child: InkWell(
            onTap: onOpen,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.border)),
              ),
              child: isWide
                  ? summary
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        summary,
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 54, right: 4),
                          child: Row(
                            children: [
                              StatusChip(
                                label:
                                    puesto['estado']?.toString() ?? 'abierto',
                                compact: true,
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: onEdit,
                                icon: const Icon(Icons.edit_outlined, size: 17),
                                label: Text(context.t('jobs.edit')),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
