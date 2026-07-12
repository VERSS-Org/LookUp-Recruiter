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
  });

  final bool showBack;
  final bool compact;

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
    final content = RefreshIndicator(
      onRefresh: () => context.read<PostulacionService>().fetchEventos(),
      child: PageContainer(
        maxWidth: 700,
        child: service.eventosError != null && eventos.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  ErrorBanner(
                    message: context.t('notif.load.error'),
                    actionLabel: context.t('common.retry'),
                    onAction: () =>
                        context.read<PostulacionService>().fetchEventos(),
                  ),
                ],
              )
            : eventos.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(22),
                    children: [
                      EmptyState(
                        icon: Icons.notifications_none,
                        title: context.t('notif.empty.title'),
                        message: context.t('notif.empty.msg'),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: eventos.length,
                    separatorBuilder: (_, index) =>
                        Divider(color: c.border, height: 1, indent: 56),
                    itemBuilder: (context, index) {
                      final evento = eventos[index] is Map
                          ? Map<String, dynamic>.from(eventos[index] as Map)
                          : const <String, dynamic>{};
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.person_add_alt_outlined,
                              size: 20,
                              color: c.inkFaint,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    evento['titulo']?.toString() ?? '—',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: c.ink,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${evento['descripcion'] ?? ''} ${context.t('notif.applied')} ${evento['titulo'] ?? ''}',
                                    style: TextStyle(
                                      color: c.inkMuted,
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
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
                    },
                  ),
      ),
    );

    if (widget.compact) {
      return SizedBox(
        key: const ValueKey('desktop-notifications-popup'),
        width: 420,
        height: 480,
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
                  IconButton(
                    tooltip: context.t('common.close'),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
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
