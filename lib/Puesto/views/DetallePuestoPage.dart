import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lookup_flutter/Puesto/views/EditarPuestoPage.dart';
import 'package:lookup_flutter/Puesto/views/PuestoCandidatosPage.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/services/puesto_service.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';
import 'package:lookup_flutter/theme/lookup_widgets.dart';

/// Detalle de una vacante con sus datos y postulantes.
class DetallePuestoPage extends StatefulWidget {
  const DetallePuestoPage({super.key, required this.puesto});

  final Map<String, dynamic> puesto;

  @override
  State<DetallePuestoPage> createState() => _DetallePuestoPageState();
}

class _DetallePuestoPageState extends State<DetallePuestoPage> {
  late Future<Map<String, dynamic>?> _puestoDetailFuture;
  bool _isChangingState = false;

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
          : context.read<PuestoService>().getPuestoDetails(puestoId);
    });
  }

  Future<void> _cambiarEstado(Map<String, dynamic> puesto) async {
    if (_isChangingState) return;
    final currentState = puesto['estado']?.toString() ?? 'abierto';
    final newState = currentState == 'abierto' ? 'cerrado' : 'abierto';
    final puestoId = _puestoId;
    final empresaId = puesto['empresa_id']?.toString();
    if (puestoId == null || empresaId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('common.cancel')),
          ),
          FilledButton(
            style: newState == 'cerrado'
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
    if (confirm != true || !mounted) return;

    setState(() => _isChangingState = true);
    try {
      final service = context.read<PuestoService>();
      final success = await service.cambiarEstadoPuesto(
        puestoId,
        newState,
        empresaId,
      );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                newState == 'cerrado' ? 'jobs.closed.ok' : 'jobs.reopened.ok',
              ),
            ),
          ),
        );
        _refreshPuestoDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              service.errorMessage ?? context.tr('common.error.generic'),
            ),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChangingState = false);
    }
  }

  Future<void> _editarPuesto(Map<String, dynamic> puesto) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditarPuestoPage(puesto: puesto)),
    );
    if (updated == true && mounted) _refreshPuestoDetails();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          key: const ValueKey('vacancy-detail-appbar'),
          toolbarHeight: 46,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: TabBar(
                  tabs: [
                    Tab(text: context.t('jobs.detail')),
                    Tab(text: context.t('jobs.candidates')),
                  ],
                ),
              ),
            ),
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
                final display = Map<String, dynamic>.from(widget.puesto);
                if (snapshot.data != null) display.addAll(snapshot.data!);
                final detail = _DetalleTab(
                  puesto: display,
                  onEditar: () => _editarPuesto(display),
                  onCambiarEstado: () => _cambiarEstado(display),
                  isChangingState: _isChangingState,
                );
                if (!snapshot.hasError) return detail;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                      child: ErrorBanner(
                        message: context.t('jobs.detail.load.error'),
                        actionLabel: context.t('common.retry'),
                        onAction: _refreshPuestoDetails,
                      ),
                    ),
                    Expanded(child: detail),
                  ],
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
    required this.isChangingState,
  });

  final Map<String, dynamic> puesto;
  final VoidCallback onEditar;
  final VoidCallback onCambiarEstado;
  final bool isChangingState;

  String _moneyNumber(dynamic value) {
    final number = value is num ? value : num.tryParse('$value');
    if (number == null) return '';
    final integer = number.round();
    final raw = '$integer';
    final chars = raw.split('').reversed.toList();
    final output = <String>[];
    for (var index = 0; index < chars.length; index++) {
      if (index > 0 && index % 3 == 0) output.add(',');
      output.add(chars[index]);
    }
    return output.reversed.join();
  }

  String _salary(BuildContext context) {
    final min = puesto['salario_min'];
    final max = puesto['salario_max'];
    if (min == null && max == null) return context.tr('salario.na');
    final currency = switch (puesto['moneda']?.toString()) {
      'USD' => r'$',
      'EUR' => '€',
      _ => 'S/',
    };
    if (min != null && max != null) {
      return '$currency ${_moneyNumber(min)} - ${_moneyNumber(max)}';
    }
    return '$currency ${_moneyNumber(min ?? max)}';
  }

  String _contract(BuildContext context) {
    final raw = puesto['tipo_contrato']?.toString() ?? '';
    final key = 'contrato.$raw';
    final value = context.tr(key);
    return value == key ? raw.replaceAll('_', ' ') : value;
  }

  String get _publishedDate {
    final raw = puesto['fecha_publicacion']?.toString() ?? '';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw.split('T').first;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final requisitos = (puesto['requisitos'] as List?) ?? const [];
    final title = puesto['titulo']?.toString() ?? '—';

    return ViewportScrollPage(
      maxWidth: 1020,
      padding: EdgeInsets.fromLTRB(
        MediaQuery.sizeOf(context).width < 600 ? 18 : 28,
        18,
        MediaQuery.sizeOf(context).width < 600 ? 18 : 28,
        36,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BrandGradientPanel(
            showBottomLeftRing: false,
            height: MediaQuery.sizeOf(context).width < 600 ? 112 : 104,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    title.trim().isEmpty ? '?' : title.trim()[0].toUpperCase(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: kBrandBlueBright,
                        ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 19,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        puesto['ubicacion']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _HeroStatus(
                  open: puesto['estado']?.toString() != 'cerrado',
                  label: context.t(
                    puesto['estado']?.toString() == 'cerrado'
                        ? 'jobs.closed.one'
                        : 'jobs.open.one',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              final description = _DescriptionColumn(
                description: puesto['descripcion']?.toString() ?? '—',
                requirements: requisitos,
              );
              final summary = _SummaryColumn(
                salary: _salary(context),
                contract: _contract(context),
                location: puesto['ubicacion']?.toString() ??
                    context.t('common.not_specified_f'),
                published: _publishedDate,
                isOpen: puesto['estado']?.toString() != 'cerrado',
                sideBySide: wide,
                onEdit: onEditar,
                onChangeStatus: onCambiarEstado,
                isChangingState: isChangingState,
              );
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    summary,
                    const SizedBox(height: 24),
                    description,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: description),
                  const SizedBox(width: 28),
                  Expanded(flex: 3, child: summary),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroStatus extends StatelessWidget {
  const _HeroStatus({required this.open, required this.label});

  final bool open;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            open ? Icons.circle : Icons.lock_outline,
            size: 10,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionColumn extends StatelessWidget {
  const _DescriptionColumn({
    required this.description,
    required this.requirements,
  });

  final String description;
  final List<dynamic> requirements;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(title: context.t('jobs.description')),
        Text(
          description,
          style: TextStyle(color: c.ink, height: 1.55, fontSize: 13.5),
        ),
        if (requirements.isNotEmpty) ...[
          const SizedBox(height: 24),
          SectionLabel(title: context.t('jobs.requirements')),
          for (final raw in requirements)
            Builder(
              builder: (context) {
                final requirement = raw is Map
                    ? Map<String, dynamic>.from(raw)
                    : <String, dynamic>{'descripcion': '$raw'};
                final mandatory = requirement['es_obligatorio'] == true;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        mandatory
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                        size: 17,
                        color: mandatory ? c.brand : c.inkFaint,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          requirement['descripcion']?.toString() ?? '',
                          style: TextStyle(
                              color: c.ink, fontSize: 13, height: 1.4),
                        ),
                      ),
                      if (!mandatory)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: c.surfaceAlt,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            context.t('jobs.desirable'),
                            style: TextStyle(
                              color: c.inkMuted,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ],
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.salary,
    required this.contract,
    required this.location,
    required this.published,
    required this.isOpen,
    required this.sideBySide,
    required this.onEdit,
    required this.onChangeStatus,
    required this.isChangingState,
  });

  final String salary;
  final String contract;
  final String location;
  final String published;
  final bool isOpen;
  final bool sideBySide;
  final VoidCallback onEdit;
  final VoidCallback onChangeStatus;
  final bool isChangingState;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: sideBySide
          ? const EdgeInsets.only(left: 18)
          : const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: sideBySide
            ? Border(left: BorderSide(color: c.border))
            : Border(bottom: BorderSide(color: c.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.t('jobs.summary').toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 12),
          Text(
            context.t('jobs.monthly_salary').toUpperCase(),
            style: TextStyle(
              color: c.inkFaint,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            salary,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: c.accent,
                ),
          ),
          const SizedBox(height: 16),
          _SummaryRow(label: context.t('form.contract'), value: contract),
          _SummaryRow(label: context.t('form.city'), value: location),
          _SummaryRow(
              label: context.t('jobs.published.short'), value: published),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 17),
            label: Text(context.t('jobs.edit')),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: isChangingState ? null : onChangeStatus,
            icon: isChangingState
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isOpen ? Icons.lock_outline : Icons.lock_open_outlined,
                    size: 17,
                  ),
            label: Text(
              context.t(isOpen ? 'jobs.close' : 'jobs.reopen'),
            ),
            style: isOpen
                ? OutlinedButton.styleFrom(
                    foregroundColor: c.danger,
                    side: BorderSide(color: c.danger.withValues(alpha: 0.45)),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            context.t(
              isOpen ? 'jobs.close.helper' : 'jobs.reopen.helper',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: c.inkFaint, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: context.colors.inkMuted, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: context.colors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
