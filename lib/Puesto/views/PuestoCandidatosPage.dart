import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/Contacto/views/MensajesEmpresa.dart';
import 'package:lookup_flutter/Perfil/views/CandidatoPerfilPage.dart';
import 'package:lookup_flutter/services/postulacion_service.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';
import 'package:lookup_flutter/theme/lookup_widgets.dart';

/// Lista de postulantes de una vacante, con filtro de proceso, cambio de
/// estado, perfil del postulante y acceso al chat. Se embebe como pestaña
/// dentro del detalle de la vacante.
class CandidatosView extends StatefulWidget {
  const CandidatosView({super.key, required this.puesto});

  final dynamic puesto;

  @override
  State<CandidatosView> createState() => _CandidatosViewState();
}

class _CandidatosViewState extends State<CandidatosView>
    with AutomaticKeepAliveClientMixin {
  String _estadoFiltro = 'todos';
  final Set<String> _actualizando = {};

  String get _puestoId => widget.puesto['puesto_id']?.toString() ?? '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void didUpdateWidget(covariant CandidatosView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.puesto['puesto_id']?.toString() ?? '';
    if (oldId != _puestoId) {
      _estadoFiltro = 'todos';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refresh();
      });
    }
  }

  Future<void> _refresh() async {
    final puestoId = _puestoId;
    if (puestoId.isEmpty) return;
    await Provider.of<PostulacionService>(context, listen: false)
        .fetchPostulacionesPorPuesto(puestoId);
  }

  List<dynamic> _filtrar(List<dynamic> postulaciones) {
    final resultado = postulaciones.where((p) {
      if (_estadoFiltro == 'todos') return true;
      final estado = canonicalEstado((p['estado'] ?? 'pendiente').toString());
      if (_estadoFiltro == 'aceptado') {
        return estado == 'aceptado' || estado == 'oferta';
      }
      return estado == _estadoFiltro;
    }).toList();
    resultado.sort((a, b) {
      final aDate = DateTime.tryParse(
        a['fecha_postulacion']?.toString() ?? '',
      );
      final bDate = DateTime.tryParse(
        b['fecha_postulacion']?.toString() ?? '',
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
    super.build(context);
    final c = context.colors;
    final postulacionService = context.watch<PostulacionService>();
    final puestoId = _puestoId;
    final todas = puestoId.isEmpty
        ? const <dynamic>[]
        : postulacionService.postulacionesFor(puestoId);
    final loadError = puestoId.isEmpty
        ? context.t('cand.load.error')
        : postulacionService.errorFor(puestoId);

    if (puestoId.isNotEmpty &&
        postulacionService.isLoadingFor(puestoId) &&
        todas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final postulaciones = _filtrar(todas);
    final filtroLabels = <String, String>{
      'todos': context.t('cand.all'),
      'pendiente': context.t('estado.pendiente'),
      'en_revision': context.t('estado.en_revision'),
      'entrevista': context.t('estado.entrevista'),
      'aceptado': context.t('estado.aceptado'),
      'rechazado': context.t('estado.rechazado'),
    };

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ViewportScrollPage(
        maxWidth: 920,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          MediaQuery.sizeOf(context).width < 600 ? 18 : 28,
          20,
          MediaQuery.sizeOf(context).width < 600 ? 18 : 28,
          36,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (loadError != null && todas.isNotEmpty) ...[
              ErrorBanner(
                key: const ValueKey('candidate-cache-error'),
                message: context.t('cand.load.error'),
                actionLabel: context.t('common.retry'),
                onAction: _refresh,
              ),
              const SizedBox(height: 8),
            ],
            if (loadError != null && todas.isEmpty)
              ErrorBanner(
                key: const ValueKey('candidate-load-error'),
                message: context.t('cand.load.error'),
                actionLabel: context.t('common.retry'),
                onAction: _refresh,
              )
            else if (todas.isEmpty)
              EmptyState(
                icon: Icons.inbox_outlined,
                title: context.t('cand.empty.title'),
                message: context.t('cand.empty.msg'),
              )
            else ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final filter = PopupMenuButton<String>(
                    key: const ValueKey('candidate-filter-menu'),
                    initialValue: _estadoFiltro,
                    position: PopupMenuPosition.under,
                    constraints:
                        const BoxConstraints(minWidth: 190, maxWidth: 240),
                    tooltip: context.t('cand.status'),
                    onSelected: (value) =>
                        setState(() => _estadoFiltro = value),
                    itemBuilder: (context) => [
                      for (final value in const [
                        'todos',
                        'pendiente',
                        'en_revision',
                        'entrevista',
                        'aceptado',
                        'rechazado',
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
                        key: const ValueKey('candidate-filter-trigger'),
                        onPressed: () {},
                        icon: const Icon(Icons.filter_list, size: 18),
                        label: Text(
                          '${filtroLabels[_estadoFiltro]} · ${postulaciones.length}',
                        ),
                        iconAlignment: IconAlignment.start,
                      ),
                    ),
                  );
                  final title = Text(
                    '${context.t('cand.title')} — ${widget.puesto['titulo'] ?? ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall,
                  );
                  if (constraints.maxWidth < 620) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title,
                        const SizedBox(height: 12),
                        filter,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: title),
                      const SizedBox(width: 16),
                      filter,
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              if (postulaciones.isEmpty)
                EmptyState(
                  icon: Icons.filter_alt_off_outlined,
                  title: context.t('cand.filtered.title'),
                  message: context.t('cand.filtered.msg'),
                )
              else
                ...postulaciones.map(
                  (postulacion) => _CandidatoRow(
                    postulacion: postulacion,
                    puestoTitulo: widget.puesto['titulo']?.toString() ?? '',
                    isUpdating: _actualizando.contains(
                      postulacion['postulacion_id']?.toString(),
                    ),
                    onCambiarEstado: (nuevo) => _cambiarEstado(
                      context,
                      postulacion['postulacion_id']?.toString() ?? '',
                      nuevo,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cambiarEstado(
      BuildContext context, String postulacionId, String nuevoEstado) async {
    if (postulacionId.isEmpty || _actualizando.contains(postulacionId)) return;
    if (nuevoEstado == 'aceptado' || nuevoEstado == 'rechazado') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.tr('cand.status.confirm.title')),
          content: Text(
            context.tr(
              nuevoEstado == 'aceptado'
                  ? 'cand.status.confirm.accepted'
                  : 'cand.status.confirm.rejected',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.tr('common.cancel')),
            ),
            FilledButton(
              style: nuevoEstado == 'rechazado'
                  ? FilledButton.styleFrom(
                      backgroundColor: context.colors.danger,
                    )
                  : null,
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.tr('common.confirm')),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    final postulacionService =
        Provider.of<PostulacionService>(context, listen: false);
    final puestoId = _puestoId;
    if (puestoId.isEmpty) return;

    setState(() => _actualizando.add(postulacionId));
    final success = await postulacionService.updateEstadoPostulacion(
      postulacionId,
      nuevoEstado,
      puestoId,
    );

    if (!mounted) return;
    setState(() => _actualizando.remove(postulacionId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '${context.tr('cand.status.updated')} ${estadoStyle(context, nuevoEstado).label}'
            : postulacionService.errorFor(puestoId) ??
                context.tr('common.error.generic')),
        backgroundColor: success ? null : context.colors.danger,
      ),
    );
  }
}

List<String> _estadoOptions(String estado) {
  // El estado final positivo en la interfaz es "aceptado" ("oferta" es un
  // sinónimo heredado del backend y se muestra igual que aceptado).
  const transitions = <String, List<String>>{
    'pendiente': [
      'pendiente',
      'en_revision',
      'entrevista',
      'aceptado',
      'rechazado'
    ],
    'en_revision': ['en_revision', 'entrevista', 'aceptado', 'rechazado'],
    'entrevista': ['entrevista', 'aceptado', 'rechazado'],
    'aceptado': ['aceptado'],
    'oferta': ['oferta'],
    'rechazado': ['rechazado'],
  };

  return transitions[estado] ?? <String>[estado];
}

class _CandidatoRow extends StatelessWidget {
  const _CandidatoRow({
    required this.postulacion,
    required this.puestoTitulo,
    required this.onCambiarEstado,
    this.isUpdating = false,
  });

  final dynamic postulacion;
  final String puestoTitulo;
  final ValueChanged<String> onCambiarEstado;
  final bool isUpdating;

  String _formatDate(BuildContext context, String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  void _abrirChat(BuildContext context, Map candidato) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatEmpresaScreen(
          hilo: {
            'postulacion_id': postulacion['postulacion_id'],
            'puesto_titulo': puestoTitulo,
            'estado_postulacion': postulacion['estado'],
            'contraparte': {
              'cuenta_id': candidato['cuenta_id'],
              'nombre': candidato['nombre_completo'],
              'foto_url': candidato['foto_url'],
            },
          },
        ),
      ),
    );
  }

  int get _documentCount {
    final documents = postulacion['documentos_adjuntos'];
    return documents is List ? documents.length : 0;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final estadoActual =
        canonicalEstado((postulacion['estado'] ?? 'pendiente').toString());
    final estadosDisponibles = _estadoOptions(estadoActual);
    final candidato = postulacion['candidato'] is Map
        ? postulacion['candidato'] as Map
        : const <String, dynamic>{};
    final nombre = candidato['nombre_completo']?.toString() ??
        context.t('common.applicant');
    final detalles = <String>[
      if ((candidato['carrera']?.toString() ?? '').isNotEmpty)
        candidato['carrera'].toString(),
      if ((candidato['ciudad']?.toString() ?? '').isNotEmpty)
        candidato['ciudad'].toString(),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InitialsAvatar(
                name: nombre,
                size: 40,
                imageUrl: candidato['foto_url']?.toString(),
                circular: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    if (detalles.isNotEmpty)
                      Text(
                        detalles,
                        style: TextStyle(fontSize: 12, color: c.inkMuted),
                      ),
                    Text(
                      '${context.t('cand.applied')} ${_formatDate(context, postulacion['fecha_postulacion'])}',
                      style: TextStyle(fontSize: 12, color: c.inkFaint),
                    ),
                    if (_documentCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 12,
                              color: c.inkFaint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_documentCount ${context.t(_documentCount == 1 ? 'cand.doc.one' : 'cand.docs')}',
                              style: TextStyle(fontSize: 12, color: c.inkFaint),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              StatusChip(label: estadoActual, compact: true),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatusMenu(
                current: estadoActual,
                options: estadosDisponibles,
                enabled: estadosDisponibles.length > 1 && !isUpdating,
                onSelected: onCambiarEstado,
              ),
              if (isUpdating)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              OutlinedButton.icon(
                onPressed: candidato['cuenta_id'] == null
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CandidatoPerfilPage(
                              cuentaId: candidato['cuenta_id'].toString(),
                              onContact: () => _abrirChat(context, candidato),
                            ),
                          ),
                        ),
                icon: const Icon(Icons.person_search_outlined, size: 20),
                label: Text(context.t('cand.view_profile')),
              ),
              FilledButton.tonalIcon(
                onPressed: candidato['cuenta_id'] == null
                    ? null
                    : () => _abrirChat(context, candidato),
                icon: const Icon(Icons.chat_outlined, size: 20),
                label: Text(context.t('cand.contact')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusMenu extends StatelessWidget {
  const _StatusMenu({
    required this.current,
    required this.options,
    required this.enabled,
    required this.onSelected,
  });

  final String current;
  final List<String> options;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final style = estadoStyle(context, current);
    return PopupMenuButton<String>(
      key: const ValueKey('candidate-status-menu'),
      enabled: enabled,
      tooltip: context.t('cand.status'),
      initialValue: current,
      constraints: const BoxConstraints(minWidth: 190, maxWidth: 240),
      position: PopupMenuPosition.under,
      onSelected: (value) {
        if (value != current) onSelected(value);
      },
      itemBuilder: (context) => [
        for (final value in options)
          PopupMenuItem<String>(
            value: value,
            height: 44,
            child: Row(
              children: [
                Icon(
                  value == current
                      ? Icons.check
                      : estadoStyle(context, value).icon,
                  size: 18,
                  color: value == current
                      ? context.colors.brand
                      : context.colors.inkFaint,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    estadoStyle(context, value).label,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: IgnorePointer(
        child: OutlinedButton.icon(
          key: const ValueKey('candidate-status-trigger'),
          onPressed: enabled ? () {} : null,
          icon: Icon(style.icon, size: 18, color: style.color),
          label: Text(style.label),
          iconAlignment: IconAlignment.start,
        ),
      ),
    );
  }
}
