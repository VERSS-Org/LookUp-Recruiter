import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lookup_flutter/Home/views/NovedadesEmpresa.dart';
import 'package:lookup_flutter/Puesto/views/DetallePuestoPage.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/services/postulacion_service.dart';
import 'package:lookup_flutter/services/profile_service.dart';
import 'package:lookup_flutter/services/puesto_service.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';
import 'package:lookup_flutter/theme/lookup_widgets.dart';

/// Panel operativo de la empresa.
class HomeEmpresa extends StatefulWidget {
  const HomeEmpresa({
    super.key,
    required this.onNavigateToOfertas,
  });

  final VoidCallback onNavigateToOfertas;

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
    final empresaId = context.read<AuthService>().cuentaId;
    if (empresaId == null) return;
    await Future.wait([
      context.read<ProfileService>().fetchProfile(empresaId),
      context.read<PuestoService>().fetchPuestosPorEmpresa(empresaId),
      context.read<PostulacionService>().fetchEventos(),
    ]);
  }

  int _count(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  String _today(BuildContext context) {
    final date = DateTime.now();
    final language = context.read<LocaleController>().language;
    const esDays = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    const esMonths = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    const enDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const enMonths = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    if (language == 'en') {
      return '${enDays[date.weekday - 1]}, ${enMonths[date.month - 1]} ${date.day}';
    }
    return '${esDays[date.weekday - 1]} ${date.day} de ${esMonths[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final profile = context.watch<ProfileService>().profileData ??
        const <String, dynamic>{};
    final puestoService = context.watch<PuestoService>();
    final eventService = context.watch<PostulacionService>();
    final puestos = puestoService.puestosEmpresa;
    final abiertas =
        puestos.where((p) => p['estado']?.toString() == 'abierto').length;
    final cerradas =
        puestos.where((p) => p['estado']?.toString() == 'cerrado').length;
    final activos = puestos.fold<int>(
      0,
      (sum, puesto) => sum + _count(puesto['postulantes_activos']),
    );
    final nombre =
        profile['nombre_completo']?.toString().trim().isNotEmpty == true
            ? profile['nombre_completo'].toString().trim()
            : context.t('common.company');
    final ordenados = List<dynamic>.from(puestos)
      ..sort((a, b) {
        final aDate =
            DateTime.tryParse(a['fecha_publicacion']?.toString() ?? '');
        final bDate =
            DateTime.tryParse(b['fecha_publicacion']?.toString() ?? '');
        return (bDate ?? DateTime(0)).compareTo(aDate ?? DateTime(0));
      });
    final recientes = ordenados.take(4).toList();
    final eventos = eventService.eventos.take(4).toList();
    final isLoading = puestoService.isLoading && puestos.isEmpty;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: ViewportScrollPage(
          maxWidth: 1080,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            MediaQuery.sizeOf(context).width < 600 ? 18 : 28,
            26,
            MediaQuery.sizeOf(context).width < 600 ? 18 : 28,
            38,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${context.t('home.greeting')} $nombre',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '${context.t('home.subtitle')} · ${_today(context)}',
                style: TextStyle(color: c.inkMuted, fontSize: 13),
              ),
              const SizedBox(height: 24),
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
                  (
                    label: context.t('home.active_candidates'),
                    value: isLoading ? '…' : '$activos',
                    color: c.accent,
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
              const SizedBox(height: 28),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 760;
                  final vacancies = _VacanciesSection(
                    puestos: recientes,
                    isLoading: isLoading,
                    error: puestoService.errorMessage,
                    onSeeAll: widget.onNavigateToOfertas,
                    onRetry: _loadInitialData,
                  );
                  final news = _NewsSection(
                    eventos: eventos,
                    onSeeAll: _openNotifications,
                  );
                  if (!wide) {
                    return Column(
                      children: [
                        vacancies,
                        const SizedBox(height: 28),
                        news,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: vacancies),
                      const SizedBox(width: 34),
                      Container(width: 1, height: 245, color: c.border),
                      const SizedBox(width: 34),
                      Expanded(flex: 4, child: news),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNotifications() {
    if (MediaQuery.sizeOf(context).width >= 960) {
      final popupHeight =
          (MediaQuery.sizeOf(context).height - 76).clamp(240.0, 430.0);
      showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel:
            MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 150),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1).animate(animation),
              alignment: Alignment.topRight,
              child: child,
            ),
          );
        },
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          final colors = dialogContext.colors;
          return SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 18),
                child: Material(
                  elevation: 0,
                  color: colors.surface,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: colors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: NovedadesEmpresa(
                    compact: true,
                    compactHeight: popupHeight,
                  ),
                ),
              ),
            ),
          );
        },
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NovedadesEmpresa(showBack: true),
      ),
    );
  }
}

class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.items});

  final List<({String label, String value, Color color})> items;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        return Container(
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: c.border),
            ),
          ),
          child: compact
              ? Wrap(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      SizedBox(
                        width: constraints.maxWidth / 2,
                        child: _StatItem(
                          item: items[i],
                          borderLeft: i.isOdd,
                          borderTop: i >= 2,
                        ),
                      ),
                  ],
                )
              : Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _StatItem(
                          item: items[i],
                          borderLeft: i > 0,
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.item,
    this.borderLeft = false,
    this.borderTop = false,
  });

  final ({String label, String value, Color color}) item;
  final bool borderLeft;
  final bool borderTop;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        border: Border(
          left: borderLeft ? BorderSide(color: c.border) : BorderSide.none,
          top: borderTop ? BorderSide(color: c.border) : BorderSide.none,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            item.value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: item.color,
                  height: 1,
                ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.inkMuted, fontSize: 12, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _VacanciesSection extends StatelessWidget {
  const _VacanciesSection({
    required this.puestos,
    required this.isLoading,
    required this.error,
    required this.onSeeAll,
    required this.onRetry,
  });

  final List<dynamic> puestos;
  final bool isLoading;
  final String? error;
  final VoidCallback onSeeAll;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          title: context.t('home.recent'),
          actionLabel: context.t('home.see_all'),
          onAction: onSeeAll,
        ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (error != null && puestos.isEmpty)
          ErrorBanner(
            message: context.t('jobs.load.error'),
            actionLabel: context.t('common.retry'),
            onAction: onRetry,
          )
        else if (puestos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              context.t('home.empty.msg'),
              style: TextStyle(color: context.colors.inkMuted),
            ),
          )
        else
          for (final puesto in puestos)
            _RecentOfferTile(
              puesto: Map<String, dynamic>.from(puesto),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetallePuestoPage(
                    puesto: Map<String, dynamic>.from(puesto),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _RecentOfferTile extends StatelessWidget {
  const _RecentOfferTile({required this.puesto, required this.onTap});

  final Map<String, dynamic> puesto;
  final VoidCallback onTap;

  int get _total {
    final value = puesto['postulantes_total'];
    return value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final title = puesto['titulo']?.toString() ?? context.t('common.untitled');
    final contractKey = 'contrato.${puesto['tipo_contrato']}';
    final contract = context.tr(contractKey);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            InitialsAvatar(name: title, size: 38),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    [
                      puesto['ubicacion']?.toString() ?? '',
                      if (contract != contractKey) contract,
                    ].where((text) => text.isNotEmpty).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.inkMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusChip(
                  label: puesto['estado']?.toString() ?? 'abierto',
                  compact: true,
                ),
                const SizedBox(height: 3),
                Text(
                  '$_total ${context.t(_total == 1 ? 'cand.count.one' : 'cand.count')}',
                  style: TextStyle(color: c.inkFaint, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsSection extends StatelessWidget {
  const _NewsSection({required this.eventos, required this.onSeeAll});

  final List<dynamic> eventos;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          title: context.t('home.news'),
          actionLabel: context.t('home.see_all'),
          onAction: onSeeAll,
        ),
        if (eventos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              context.t('notif.empty.msg'),
              style: TextStyle(color: context.colors.inkMuted),
            ),
          )
        else
          for (final raw in eventos)
            if (raw is Map) _EventTile(evento: Map<String, dynamic>.from(raw)),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.evento});

  final Map<String, dynamic> evento;

  String _relative(BuildContext context) {
    final parsed = DateTime.tryParse(evento['fecha']?.toString() ?? '');
    if (parsed == null) return '';
    final diff = DateTime.now().difference(parsed.toLocal());
    if (diff.inHours < 1) return context.t('time.now');
    if (diff.inDays < 1) {
      return context
          .t('time.hours_ago')
          .replaceFirst('{count}', '${diff.inHours}');
    }
    if (diff.inDays == 1) return context.t('time.yesterday');
    return context.t('time.days_ago').replaceFirst('{count}', '${diff.inDays}');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final person =
        evento['descripcion']?.toString() ?? context.t('common.applicant');
    final vacancy = evento['titulo']?.toString() ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          InitialsAvatar(name: person, size: 34, circular: true),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${context.t('notif.applied')} $vacancy',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.inkMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _relative(context),
            style: TextStyle(color: c.inkFaint, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
