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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final puestoId = widget.puesto['puesto_id']?.toString();
    if (puestoId == null || puestoId.isEmpty) return;
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

    if (postulacionService.isLoading &&
        postulacionService.postulacionesPuesto.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final todas = postulacionService.postulacionesPuesto;
    final postulaciones = _filtrar(todas);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: PageContainer(
        maxWidth: 860,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
          children: [
            if (postulacionService.errorMessage != null &&
                todas.isNotEmpty) ...[
              ErrorBanner(
                message: context.t('cand.load.error'),
                actionLabel: context.t('common.retry'),
                onAction: _refresh,
              ),
              const SizedBox(height: 8),
            ],
            if (postulacionService.errorMessage != null && todas.isEmpty)
              ErrorBanner(
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'todos',
                      label: Text(context.t('cand.all')),
                    ),
                    ButtonSegment(
                      value: 'pendiente',
                      label: Text(context.t('estado.pendiente')),
                    ),
                    ButtonSegment(
                      value: 'en_revision',
                      label: Text(context.t('estado.en_revision')),
                    ),
                    ButtonSegment(
                      value: 'entrevista',
                      label: Text(context.t('estado.entrevista')),
                    ),
                    ButtonSegment(
                      value: 'aceptado',
                      label: Text(context.t('estado.aceptado')),
                    ),
                    ButtonSegment(
                      value: 'rechazado',
                      label: Text(context.t('estado.rechazado')),
                    ),
                  ],
                  selected: {_estadoFiltro},
                  onSelectionChanged: (selection) =>
                      setState(() => _estadoFiltro = selection.first),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${postulaciones.length} ${postulaciones.length == 1 ? context.t('cand.count.one') : context.t('cand.count')}',
                style: TextStyle(color: c.inkFaint, fontSize: 13),
              ),
              const SizedBox(height: 4),
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
    final puestoId = widget.puesto['puesto_id']?.toString();
    if (puestoId == null || puestoId.isEmpty) return;

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
            : postulacionService.errorMessage ??
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
                size: 46,
                imageUrl: candidato['foto_url']?.toString(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    if (detalles.isNotEmpty)
                      Text(
                        detalles,
                        style: TextStyle(fontSize: 13, color: c.inkMuted),
                      ),
                    Text(
                      '${context.t('cand.applied')} ${_formatDate(context, postulacion['fecha_postulacion'])}',
                      style: TextStyle(fontSize: 12.5, color: c.inkFaint),
                    ),
                  ],
                ),
              ),
              StatusChip(label: estadoActual, compact: true),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusMenu(
                current: estadoActual,
                options: estadosDisponibles,
                enabled: estadosDisponibles.length > 1 && !isUpdating,
                onSelected: onCambiarEstado,
              ),
              if (isUpdating) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: context.t('cand.view_profile'),
                onPressed: candidato['cuenta_id'] == null
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CandidatoPerfilPage(
                              cuentaId: candidato['cuenta_id'].toString(),
                            ),
                          ),
                        ),
                icon: const Icon(Icons.person_search_outlined, size: 20),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                tooltip: context.t('cand.contact'),
                onPressed: candidato['cuenta_id'] == null
                    ? null
                    : () => _abrirChat(context, candidato),
                icon: const Icon(Icons.chat_outlined, size: 20),
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
