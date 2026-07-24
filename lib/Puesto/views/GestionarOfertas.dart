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
    final filtroLabels = <String, String>{
      'todas': context.t('jobs.all'),
      'abierto': context.t('jobs.open'),
      'cerrado': context.t('jobs.closed'),
    };

    return Scaffold(
      floatingActionButton: compact
          ? FloatingActionButton.extended(
              onPressed: _crearVacante,
              icon: const Icon(Icons.add),
              label: Text(context.t('home.publish')),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ViewportScrollPage(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            compact ? 18 : 28,
            24,
            compact ? 18 : 28,
            compact ? 104 : 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t('jobs.title'),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${puestoService.puestosEmpresa.length} ${puestoService.puestosEmpresa.length == 1 ? context.t('jobs.count.one') : context.t('jobs.count')} ${context.t('jobs.published.short')}',
                          style: TextStyle(color: c.inkMuted, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  if (!compact)
                    FilledButton.icon(
                      key: const ValueKey('publish-vacancy-button'),
                      onPressed: _crearVacante,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(context.t('home.publish')),
                    ),
                ],
              ),
              const SizedBox(height: 20),
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
                  final filtro = PopupMenuButton<String>(
                    key: const ValueKey('vacancy-filter-menu'),
                    initialValue: _estadoFiltro,
                    position: PopupMenuPosition.under,
                    constraints:
                        const BoxConstraints(minWidth: 170, maxWidth: 220),
                    tooltip: context.t('jobs.filter'),
                    onSelected: (value) =>
                        setState(() => _estadoFiltro = value),
                    itemBuilder: (context) => [
                      for (final value in const [
                        'todas',
                        'abierto',
                        'cerrado',
                      ])
                        PopupMenuItem<String>(
                          value: value,
                          height: 44,
                          child: Row(
                            children: [
                              Icon(
                                value == _estadoFiltro
                                    ? Icons.check
                                    : Icons.circle_outlined,
                                size: 18,
                                color: value == _estadoFiltro
                                    ? c.brand
                                    : c.inkFaint,
                              ),
                              const SizedBox(width: 10),
                              Text(filtroLabels[value]!),
                            ],
                          ),
                        ),
                    ],
                    child: IgnorePointer(
                      child: OutlinedButton.icon(
                        key: const ValueKey('vacancy-filter-trigger'),
                        onPressed: () {},
                        icon: const Icon(Icons.filter_list, size: 18),
                        label: Text(filtroLabels[_estadoFiltro]!),
                      ),
                    ),
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
                      Align(alignment: Alignment.centerLeft, child: filtro),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
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
                )
              else ...[
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

  int get _postulantes {
    final value = puesto['postulantes_total'];
    return value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  }

  String _salario(BuildContext context) {
    final min = puesto['salario_min'];
    final max = puesto['salario_max'];
    final currency = puesto['moneda']?.toString() ?? 'PEN';
    String format(dynamic value) {
      final number = value is num ? value : num.tryParse('$value');
      if (number == null) return '';
      return number == number.roundToDouble()
          ? number.toInt().toString()
          : number.toStringAsFixed(2);
    }

    if (min == null && max == null) return context.t('salario.na');
    if (min != null && max != null) {
      return '$currency ${format(min)} - ${format(max)}';
    }
    return '$currency ${format(min ?? max)}';
  }

  String _contract(BuildContext context) {
    final raw = puesto['tipo_contrato']?.toString() ?? '';
    final key = 'contrato.$raw';
    final translated = context.tr(key);
    return translated == key ? raw.replaceAll('_', ' ') : translated;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final titulo = puesto['titulo']?.toString() ?? context.t('common.untitled');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 680;
        final identity = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InitialsAvatar(name: titulo, size: 38),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 7,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: c.ink,
                          fontSize: 13.5,
                        ),
                      ),
                      StatusChip(
                        label: puesto['estado']?.toString() ?? 'abierto',
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      puesto['ubicacion']?.toString() ??
                          context.t('common.location.unspecified'),
                      _contract(context),
                      _salario(context),
                      if (_fecha(context).isNotEmpty)
                        '${context.t('jobs.published')} ${_fecha(context)}',
                    ].where((value) => value.isNotEmpty).join(' · '),
                    maxLines: isWide ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.inkMuted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        return Semantics(
          button: true,
          label: titulo,
          child: InkWell(
            onTap: onOpen,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.border)),
              ),
              child: isWide
                  ? Row(
                      children: [
                        Expanded(child: identity),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 72,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$_postulantes',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: c.ink),
                              ),
                              Text(
                                context.t(
                                  _postulantes == 1
                                      ? 'cand.count.one'
                                      : 'cand.count',
                                ),
                                style:
                                    TextStyle(color: c.inkFaint, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: context.t('jobs.edit'),
                          onPressed: onEdit,
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: c.inkMuted,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 19,
                          color: c.inkFaint,
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        identity,
                        const SizedBox(height: 7),
                        Padding(
                          padding: const EdgeInsets.only(left: 49),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$_postulantes ${context.t(_postulantes == 1 ? 'cand.count.one' : 'cand.count')}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: c.inkFaint,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.outlined(
                                tooltip: context.t('jobs.edit'),
                                onPressed: onEdit,
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.edit_outlined, size: 17),
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
