import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/puesto_service.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/Puesto/views/EditarPuestoPage.dart';
import 'package:lookup_flutter/Puesto/views/PuestoCandidatosPage.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';
import 'package:lookup_flutter/theme/lookup_widgets.dart';

/// Detalle de una vacante con dos pestañas: detalle y postulantes.
class DetallePuestoPage extends StatefulWidget {
  final Map<String, dynamic> puesto;

  const DetallePuestoPage({super.key, required this.puesto});

  @override
  State<DetallePuestoPage> createState() => _DetallePuestoPageState();
}

class _DetallePuestoPageState extends State<DetallePuestoPage> {
  late Future<Map<String, dynamic>?> _puestoDetailFuture;

  String? get _puestoId =>
      (widget.puesto['puesto_id'] ?? widget.puesto['id'])?.toString();

  @override
  void initState() {
    super.initState();
    _refreshPuestoDetails();
  }

  void _refreshPuestoDetails() {
    final puestoId = _puestoId;
    setState(() {
      _puestoDetailFuture = puestoId == null
          ? Future.value(null)
          : Provider.of<PuestoService>(context, listen: false)
              .getPuestoDetails(puestoId);
    });
  }

  Future<void> _cambiarEstado(Map<String, dynamic> puesto) async {
    final currentState = puesto['estado']?.toString() ?? 'abierto';
    final newState = currentState == 'abierto' ? 'cerrado' : 'abierto';

    final puestoId = _puestoId;
    final empresaId = puesto['empresa_id']?.toString();
    if (puestoId == null || empresaId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            newState == 'cerrado'
                ? context.tr('jobs.close')
                : context.tr('jobs.reopen'),
          ),
          content: Text(
            newState == 'cerrado'
                ? context.tr('jobs.close.confirm')
                : context.tr('jobs.reopen.confirm'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.tr('common.cancel')),
            ),
            FilledButton(
              style: newState == 'cerrado'
                  ? FilledButton.styleFrom(
                      backgroundColor: context.colors.danger,
                    )
                  : null,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.tr('common.confirm')),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    final puestoService = Provider.of<PuestoService>(context, listen: false);
    final success =
        await puestoService.cambiarEstadoPuesto(puestoId, newState, empresaId);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newState == 'cerrado'
                ? context.tr('jobs.closed.ok')
                : context.tr('jobs.reopened.ok'),
          ),
        ),
      );
      _refreshPuestoDetails();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(puestoService.errorMessage ?? 'Error'),
          backgroundColor: context.colors.danger,
        ),
      );
    }
  }

  Future<void> _editarPuesto(Map<String, dynamic> puesto) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => EditarPuestoPage(puesto: puesto)),
    );
    if (updated == true && mounted) {
      _refreshPuestoDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.puesto['titulo']?.toString() ?? context.t('jobs.detail'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: context.t('jobs.detail')),
              Tab(text: context.t('jobs.candidates')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FutureBuilder<Map<String, dynamic>?>(
              future: _puestoDetailFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final displayPuesto = Map<String, dynamic>.from(widget.puesto);
                if (snapshot.data != null) {
                  displayPuesto.addAll(snapshot.data!);
                }
                return _DetalleTab(
                  puesto: displayPuesto,
                  onEditar: () => _editarPuesto(displayPuesto),
                  onCambiarEstado: () => _cambiarEstado(displayPuesto),
                );
              },
            ),
            CandidatosView(puesto: widget.puesto),
          ],
        ),
      ),
    );
  }
}

class _DetalleTab extends StatelessWidget {
  const _DetalleTab({
    required this.puesto,
    required this.onEditar,
    required this.onCambiarEstado,
  });

  final Map<String, dynamic> puesto;
  final VoidCallback onEditar;
  final VoidCallback onCambiarEstado;

  String _salario(BuildContext context) {
    final min = puesto['salario_min'];
    final max = puesto['salario_max'];
    final moneda = puesto['moneda']?.toString() ?? 'PEN';
    String fmt(dynamic v) {
      final n = v is num
          ? v.toDouble()
          : double.tryParse(v.toString().replaceAll(',', '.'));
      if (n == null) return v.toString();
      return n == n.roundToDouble()
          ? n.toInt().toString()
          : n.toStringAsFixed(2);
    }

    if (min == null && max == null) return context.tr('salario.na');
    if (min != null && max != null) return '${fmt(min)} - ${fmt(max)} $moneda';
    return '${fmt(min ?? max)} $moneda';
  }

  String _contrato(BuildContext context) {
    final tipo = puesto['tipo_contrato']?.toString() ?? '';
    if (tipo.isEmpty) return context.tr('contrato.na');
    final key = 'contrato.$tipo';
    final label = context.tr(key);
    return label == key ? tipo.replaceAll('_', ' ') : label;
  }

  String get _fechaPublicacion {
    final raw = puesto['fecha_publicacion']?.toString();
    if (raw == null || raw.isEmpty) return '';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw.split('T').first;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final estadoActual = puesto['estado']?.toString() ?? 'abierto';
    final isAbierto = estadoActual == 'abierto';
    final requisitos = (puesto['requisitos'] as List?) ?? const [];
    final titulo = puesto['titulo']?.toString() ?? '—';

    return PageContainer(
      maxWidth: 860,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          MediaQuery.sizeOf(context).width < 480 ? 16 : 22,
          20,
          MediaQuery.sizeOf(context).width < 480 ? 16 : 22,
          32,
        ),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 430;
              final identity = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InitialsAvatar(
                    name: titulo,
                    size: 52,
                    fallbackIcon: Icons.work_outline,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (_fechaPublicacion.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            '${context.t('jobs.published')} $_fechaPublicacion',
                            style: TextStyle(
                              color: c.inkMuted,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    identity,
                    const SizedBox(height: 10),
                    StatusChip(label: estadoActual),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: identity),
                  const SizedBox(width: 12),
                  StatusChip(label: estadoActual),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(
                icon: Icons.location_on_outlined,
                label: puesto['ubicacion']?.toString().isNotEmpty == true
                    ? puesto['ubicacion'].toString()
                    : context.t('common.not_specified_f'),
              ),
              _MetaChip(icon: Icons.badge_outlined, label: _contrato(context)),
              _MetaChip(
                icon: Icons.payments_outlined,
                label: _salario(context),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionLabel(title: context.t('jobs.description')),
          Text(
            puesto['descripcion']?.toString() ?? '—',
            style: TextStyle(color: c.ink, height: 1.55, fontSize: 14.5),
          ),
          if (requisitos.isNotEmpty) ...[
            const SizedBox(height: 22),
            SectionLabel(title: context.t('jobs.requirements')),
            ...requisitos.map((req) {
              final texto = req is Map
                  ? (req['descripcion']?.toString() ?? '')
                  : req.toString();
              final obligatorio = req is Map && req['es_obligatorio'] == true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      obligatorio
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      size: 19,
                      color: obligatorio ? c.brand : c.inkFaint,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        texto,
                        style:
                            TextStyle(color: c.ink, height: 1.4, fontSize: 14),
                      ),
                    ),
                    if (!obligatorio)
                      Text(
                        context.t('jobs.desirable'),
                        style: TextStyle(
                          color: c.inkFaint,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 560;
              final editar = OutlinedButton.icon(
                onPressed: onEditar,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(context.t('jobs.edit')),
              );
              final estado = isAbierto
                  ? OutlinedButton.icon(
                      onPressed: onCambiarEstado,
                      icon: const Icon(Icons.lock_outline, size: 18),
                      label: Text(context.t('jobs.close')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.danger,
                        side: BorderSide(
                          color: c.danger.withValues(alpha: 0.4),
                        ),
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: onCambiarEstado,
                      icon: const Icon(Icons.lock_open_outlined, size: 18),
                      label: Text(context.t('jobs.reopen')),
                      style: FilledButton.styleFrom(
                        backgroundColor: c.success,
                      ),
                    );

              if (!isWide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [editar, const SizedBox(height: 10), estado],
                );
              }
              return Row(
                children: [
                  Expanded(child: editar),
                  const SizedBox(width: 12),
                  Expanded(child: estado),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxWidth =
        (MediaQuery.sizeOf(context).width - 64).clamp(160.0, 520.0).toDouble();
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c.inkMuted),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: c.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
