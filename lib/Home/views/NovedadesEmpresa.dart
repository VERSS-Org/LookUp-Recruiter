import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/services/postulacion_service.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';
import 'package:lookup_flutter/theme/lookup_widgets.dart';

/// Notificaciones de la empresa: nuevas postulaciones de los últimos 7 días.
class NovedadesEmpresa extends StatefulWidget {
  const NovedadesEmpresa({
    super.key,
    this.showBack = false,
    this.compact = false,
    this.compactHeight = 430,
  });

  final bool showBack;
  final bool compact;
  final double compactHeight;

  @override
  State<NovedadesEmpresa> createState() => _NovedadesEmpresaState();
}

class _NovedadesEmpresaState extends State<NovedadesEmpresa> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final service = context.read<PostulacionService>();
      await service.fetchEventos();
      if (!mounted || widget.compact || service.eventosError != null) return;
      await service.markEventosSeen();
    });
  }

  String _relativa(BuildContext context, String? raw) {
    final parsed = raw == null ? null : DateTime.tryParse(raw);
    final date = parsed?.toLocal();
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return context.tr('time.now');
    if (diff.inHours < 1) {
      return context
          .tr('time.minutes_ago')
          .replaceFirst('{count}', '${diff.inMinutes}');
    }
    if (diff.inDays < 1) {
      return context
          .tr('time.hours_ago')
          .replaceFirst('{count}', '${diff.inHours}');
    }
    if (diff.inDays == 1) return context.tr('time.yesterday');
    return context
        .tr('time.days_ago')
        .replaceFirst('{count}', '${diff.inDays}');
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PostulacionService>();
    final c = context.colors;
    final eventos = service.eventos;

    Widget eventRow(int index) {
      final evento = eventos[index] is Map
          ? Map<String, dynamic>.from(eventos[index] as Map)
          : const <String, dynamic>{};
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InitialsAvatar(
              name: evento['descripcion']?.toString() ??
                  context.t('common.applicant'),
              size: widget.compact ? 34 : 40,
              circular: true,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text:
                          '${evento['descripcion'] ?? context.t('common.applicant')} ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: '${context.t('notif.applied')} '),
                    TextSpan(
                      text: evento['titulo']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c.ink,
                  fontSize: widget.compact ? 11.5 : 13,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _relativa(context, evento['fecha']?.toString()),
              style: TextStyle(color: c.inkFaint, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final statusContent = service.eventosError != null && eventos.isEmpty
        ? <Widget>[
            ErrorBanner(
              message: context.t('notif.load.error'),
              actionLabel: context.t('common.retry'),
              onAction: () => context.read<PostulacionService>().fetchEventos(),
            ),
          ]
        : eventos.isEmpty
            ? <Widget>[
                EmptyState(
                  icon: Icons.notifications_none,
                  title: context.t('notif.empty.title'),
                  message: context.t('notif.empty.msg'),
                ),
              ]
            : <Widget>[
                for (var index = 0; index < eventos.length; index++) ...[
                  eventRow(index),
                  if (index < eventos.length - 1)
                    Divider(color: c.border, height: 1, indent: 56),
                ],
              ];

    final content = RefreshIndicator(
      onRefresh: () => context.read<PostulacionService>().fetchEventos(),
      child: widget.compact
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: statusContent,
            )
          : ViewportScrollPage(
              maxWidth: 700,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: statusContent,
              ),
            ),
    );

    if (widget.compact) {
      return SizedBox(
        key: const ValueKey('desktop-notifications-popup'),
        width: 420,
        height: widget.compactHeight,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.t('notif.title'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: service.unseenEventos == 0
                        ? null
                        : () => context
                            .read<PostulacionService>()
                            .markEventosSeen(),
                    child: Text(context.t('notif.mark_read')),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: c.border),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      key: const ValueKey('mobile-notifications-page'),
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: widget.showBack,
        leading: widget.showBack
            ? IconButton(
                tooltip: context.t('common.back'),
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(context.t('notif.title')),
      ),
      body: content,
    );
  }
}
