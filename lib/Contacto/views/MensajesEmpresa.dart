import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/services/contacto_service.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';
import 'package:lookup_flutter/theme/lookup_widgets.dart';

/// Mensajes de la empresa.
///
/// En pantallas anchas: dos paneles (lista de chats + conversación). En
/// móvil: lista y chat apilados.
class MensajesEmpresa extends StatefulWidget {
  const MensajesEmpresa({super.key, this.showBack = false});

  final bool showBack;

  @override
  State<MensajesEmpresa> createState() => _MensajesEmpresaState();
}

class _MensajesEmpresaState extends State<MensajesEmpresa> {
  final _searchController = TextEditingController();
  Map<String, dynamic>? _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactoService>().fetchBandeja();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _open(Map<String, dynamic> hilo, bool isWide) {
    if (isWide) {
      setState(() => _selected = hilo);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatEmpresaScreen(hilo: hilo)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _build(context, constraints.maxWidth),
    );
  }

  Widget _build(BuildContext context, double availableWidth) {
    final contactoService = context.watch<ContactoService>();
    final c = context.colors;
    final bandeja = contactoService.bandeja;
    final query = _query.trim().toLowerCase();
    final conversaciones = bandeja.where((item) {
      if (item is! Map) return false;
      if (query.isEmpty) return true;
      final contraparte = item['contraparte'] is Map
          ? item['contraparte'] as Map
          : const <String, dynamic>{};
      final texto = [
        contraparte['nombre'],
        item['puesto_titulo'],
      ].whereType<Object>().join(' ').toLowerCase();
      return texto.contains(query);
    }).toList();
    // Se mide el ancho real del panel para que los dos paneles aparezcan tanto
    // dentro del shell como en una ruta independiente.
    final isWide = availableWidth >= 820;

    final lista = contactoService.isBandejaLoading && bandeja.isEmpty
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(40),
            children: const [Center(child: CircularProgressIndicator())],
          )
        : contactoService.bandejaError != null && bandeja.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(18),
                children: [
                  ErrorBanner(
                    message: context.t('chat.load.error'),
                    actionLabel: context.t('common.retry'),
                    onAction: () =>
                        context.read<ContactoService>().fetchBandeja(),
                  ),
                ],
              )
            : conversaciones.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(22),
                    children: [
                      EmptyState(
                        icon: query.isEmpty
                            ? Icons.chat_outlined
                            : Icons.search_off_outlined,
                        title: query.isEmpty
                            ? context.t('chat.empty.title')
                            : context.t('jobs.filtered.title'),
                        message: query.isEmpty
                            ? context.t('chat.empty.msg')
                            : context.t('chat.search.empty'),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: conversaciones.length,
                    separatorBuilder: (_, index) =>
                        Divider(color: c.border, height: 1, indent: 78),
                    itemBuilder: (context, index) {
                      final hilo = Map<String, dynamic>.from(
                          conversaciones[index] as Map);
                      return _ThreadTile(
                        hilo: hilo,
                        selected: isWide &&
                            _selected?['postulacion_id'] ==
                                hilo['postulacion_id'],
                        onTap: () => _open(hilo, isWide),
                      );
                    },
                  );

    final search = Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: context.t('chat.search'),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: context.t('common.clear'),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  icon: const Icon(Icons.close),
                ),
          filled: true,
          fillColor: c.surfaceAlt,
        ),
      ),
    );

    final listPanel = Column(
      children: [
        search,
        Divider(color: c.border, height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<ContactoService>().fetchBandeja(),
            child: lista,
          ),
        ),
      ],
    );

    if (isWide) {
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: availableWidth >= 1100 ? 380 : 340,
              child: Column(
                children: [
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: c.border)),
                    ),
                    child: Text(
                      context.t('chat.title'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                  ),
                  Expanded(child: listPanel),
                ],
              ),
            ),
            VerticalDivider(width: 1, color: c.border),
            Expanded(
              child: _selected == null
                  ? Container(
                      color: c.background,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const BrandMark(size: 46),
                            const SizedBox(height: 14),
                            Text(
                              context.t('chat.empty.title'),
                              style: TextStyle(
                                color: c.inkMuted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ChatEmpresaView(
                      key: ValueKey(_selected!['postulacion_id']),
                      hilo: _selected!,
                    ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
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
        title: Text(context.t('chat.title')),
      ),
      body: listPanel,
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({
    required this.hilo,
    required this.onTap,
    this.selected = false,
  });

  final Map<String, dynamic> hilo;
  final VoidCallback onTap;
  final bool selected;

  String _hora(String? raw) {
    if (raw == null) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '';
    final date = parsed.toLocal();
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final contraparte = hilo['contraparte'] is Map
        ? Map<String, dynamic>.from(hilo['contraparte'] as Map)
        : const <String, dynamic>{};
    final ultimo = hilo['ultimo_mensaje'] is Map
        ? Map<String, dynamic>.from(hilo['ultimo_mensaje'] as Map)
        : const <String, dynamic>{};
    final unread = (hilo['no_leidos'] as num?)?.toInt() ?? 0;
    final esMio = ultimo['remitente_rol']?.toString() == 'empresa';

    return Material(
      color: selected ? c.surfaceAlt : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              InitialsAvatar(
                name: contraparte['nombre']?.toString() ?? '?',
                size: 48,
                imageUrl: contraparte['foto_url']?.toString(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            contraparte['nombre']?.toString() ??
                                context.t('common.applicant'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                              color: c.ink,
                            ),
                          ),
                        ),
                        Text(
                          _hora(ultimo['fecha']?.toString()),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: unread > 0 ? c.accent : c.inkFaint,
                            fontWeight:
                                unread > 0 ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      hilo['puesto_titulo']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: c.inkFaint),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${esMio ? '${context.t('chat.you')}: ' : ''}${ultimo['texto'] ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: unread > 0 ? c.ink : c.inkMuted,
                              fontWeight: unread > 0
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: c.accent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chat como página completa (móvil).
class ChatEmpresaScreen extends StatelessWidget {
  const ChatEmpresaScreen({super.key, required this.hilo});

  final Map<String, dynamic> hilo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: ChatEmpresaView(hilo: hilo, showBack: true)),
    );
  }
}

/// Conversación de la empresa con un postulante, con acciones de proceso
/// (marcar aceptado / rechazar) en el menú de la cabecera.
class ChatEmpresaView extends StatefulWidget {
  const ChatEmpresaView({super.key, required this.hilo, this.showBack = false});

  final Map<String, dynamic> hilo;
  final bool showBack;

  @override
  State<ChatEmpresaView> createState() => _ChatEmpresaViewState();
}

class _ChatEmpresaViewState extends State<ChatEmpresaView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;
  bool _isSending = false;
  bool _isPolling = false;
  late String _estadoActual;

  String get _postulacionId => widget.hilo['postulacion_id']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _estadoActual = canonicalEstado(
      widget.hilo['estado_postulacion']?.toString() ?? 'pendiente',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_postulacionId.isEmpty) return;
      final service = context.read<ContactoService>();
      await service.fetchContactos(_postulacionId);
      if (service.errorMessage == null) {
        await service.marcarLeidos(_postulacionId);
      }
      _scrollToBottom(animated: false);
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _poll());
  }

  Future<void> _poll() async {
    if (!mounted || _isPolling || _postulacionId.isEmpty) return;
    _isPolling = true;
    try {
      final service = context.read<ContactoService>();
      final before = service.contactosFor(_postulacionId).length;
      await service.fetchContactos(_postulacionId);
      if (!mounted) return;
      if (service.errorMessage == null &&
          service.contactosFor(_postulacionId).length != before) {
        await service.marcarLeidos(_postulacionId);
        _scrollToBottom();
      }
    } finally {
      _isPolling = false;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  Future<void> _send() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _isSending || _postulacionId.isEmpty) return;
    setState(() => _isSending = true);
    _controller.clear();
    try {
      await context.read<ContactoService>().enviarMensaje(
            _postulacionId,
            texto,
          );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        _controller.text = texto;
        _controller.selection = TextSelection.collapsed(offset: texto.length);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('chat.send.error')),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _enviarFeedback(String tipo) async {
    final auth = context.read<AuthService>();
    final service = context.read<ContactoService>();
    final contraparte = widget.hilo['contraparte'] is Map
        ? Map<String, dynamic>.from(widget.hilo['contraparte'] as Map)
        : const <String, dynamic>{};
    final candidatoId = contraparte['cuenta_id']?.toString();
    if (candidatoId == null || auth.cuentaId == null) return;

    String? mensaje;
    String? motivo;

    if (tipo == 'rechazo') {
      final resultado = await showDialog<(String, String)>(
        context: context,
        builder: (_) => const _RechazoDialog(),
      );
      if (resultado == null) return;
      mensaje = resultado.$1;
      motivo = resultado.$2;
    } else {
      final controller = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.tr('chat.approve')),
          content: TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(hintText: context.tr('chat.reply')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.tr('common.cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.tr('common.send')),
            ),
          ],
        ),
      );
      final texto = controller.text.trim();
      controller.dispose();
      if (ok != true) return;
      mensaje = texto;
      if (mensaje.isEmpty) return;
    }

    if (!mounted) return;
    final success = await service.enviarFeedback(
      postulacionId: _postulacionId,
      empresaId: auth.cuentaId!,
      cuentaId: candidatoId,
      tipoFeedback: tipo,
      mensajeTexto: mensaje,
      motivoRechazo: motivo,
    );
    if (!mounted) return;
    if (success) {
      setState(() {
        _estadoActual = tipo == 'aprobacion' ? 'aceptado' : 'rechazado';
      });
      _scrollToBottom();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('chat.sent'))),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(service.errorMessage ?? 'Error'),
          backgroundColor: context.colors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final service = context.watch<ContactoService>();
    final mensajes = service.contactosFor(_postulacionId);
    final contraparte = widget.hilo['contraparte'] is Map
        ? Map<String, dynamic>.from(widget.hilo['contraparte'] as Map)
        : const <String, dynamic>{};

    return Container(
      color: c.background,
      child: Column(
        children: [
          Container(
            height: 56,
            padding: EdgeInsets.only(
              left: widget.showBack ? 4 : 16,
              right: 4,
            ),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            child: Row(
              children: [
                if (widget.showBack)
                  IconButton(
                    tooltip: context.t('common.back'),
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                InitialsAvatar(
                  name: contraparte['nombre']?.toString() ?? '?',
                  size: 36,
                  imageUrl: contraparte['foto_url']?.toString(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contraparte['nombre']?.toString() ??
                            context.t('common.applicant'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                      Text(
                        widget.hilo['puesto_titulo']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: c.inkFaint),
                      ),
                    ],
                  ),
                ),
                if (_estadoActual != 'aceptado' && _estadoActual != 'rechazado')
                  PopupMenuButton<String>(
                    tooltip: context.t('chat.actions'),
                    icon: const Icon(Icons.more_vert),
                    onSelected: _enviarFeedback,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'aprobacion',
                        child: Row(
                          children: [
                            Icon(
                              Icons.thumb_up_alt_outlined,
                              size: 19,
                              color: c.success,
                            ),
                            const SizedBox(width: 10),
                            Text(context.tr('chat.approve')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'rechazo',
                        child: Row(
                          children: [
                            Icon(
                              Icons.cancel_outlined,
                              size: 19,
                              color: c.danger,
                            ),
                            const SizedBox(width: 10),
                            Text(context.tr('chat.reject')),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            child:
                service.isLoadingContactos(_postulacionId) && mensajes.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : service.errorMessage != null && mensajes.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(18),
                            children: [
                              ErrorBanner(
                                message: context.t('chat.messages.error'),
                                actionLabel: context.t('common.retry'),
                                onAction: () => context
                                    .read<ContactoService>()
                                    .fetchContactos(_postulacionId),
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                            itemCount: mensajes.length,
                            itemBuilder: (context, index) => _ChatBubble(
                              contacto: mensajes[index] is Map
                                  ? Map<String, dynamic>.from(
                                      mensajes[index] as Map,
                                    )
                                  : const <String, dynamic>{},
                            ),
                          ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: context.t('chat.reply'),
                      fillColor: c.surfaceAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(color: c.brand),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: c.brand,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _isSending ? null : _send,
                    child: Padding(
                      padding: const EdgeInsets.all(11),
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.contacto});

  final Map<String, dynamic> contacto;

  String _hora(String? raw) {
    if (raw == null) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '';
    final date = parsed.toLocal();
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final feedback = contacto['ultimo_feedback'] is Map
        ? Map<String, dynamic>.from(contacto['ultimo_feedback'] as Map)
        : const <String, dynamic>{};
    final tipo = feedback['tipo']?.toString() ?? 'otro';
    final mensaje = feedback['mensaje']?.toString() ?? '';
    final motivo = feedback['motivo_rechazo']?.toString();
    final isMine = contacto['remitente_rol']?.toString() == 'empresa';
    final esEvento = tipo == 'aprobacion' || tipo == 'rechazo';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        margin: EdgeInsets.only(
          bottom: 6,
          left: isMine ? 56 : 0,
          right: isMine ? 0 : 56,
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          color: isMine
              ? (context.isDark
                  ? const Color(0xFF31405F)
                  : const Color(0xFFDCE5FA))
              : c.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMine ? 14 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (esEvento)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: StatusChip(
                  label: tipo == 'aprobacion' ? 'aceptado' : 'rechazado',
                  compact: true,
                ),
              ),
            Text(
              mensaje,
              style: TextStyle(color: c.ink, fontSize: 14, height: 1.4),
            ),
            if (motivo != null && motivo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  '${context.t('chat.reason')}: $motivo',
                  style: TextStyle(
                    color: c.inkMuted,
                    fontStyle: FontStyle.italic,
                    fontSize: 12.5,
                  ),
                ),
              ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _hora(contacto['fecha_hora']?.toString()),
                style: TextStyle(fontSize: 10.5, color: c.inkFaint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo de rechazo: mensaje + motivo obligatorio.
class _RechazoDialog extends StatefulWidget {
  const _RechazoDialog();

  @override
  State<_RechazoDialog> createState() => _RechazoDialogState();
}

class _RechazoDialogState extends State<_RechazoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _mensajeController = TextEditingController();
  final _motivoController = TextEditingController();

  @override
  void dispose() {
    _mensajeController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.t('chat.reject')),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _mensajeController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: context.t('chat.reply'),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? context.tr('form.required')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _motivoController,
                decoration: InputDecoration(
                  labelText: context.t('chat.reject.reason'),
                  hintText: context.t('chat.reject.reason.hint'),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? context.tr('form.required')
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.t('common.cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.danger,
          ),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, (
              _mensajeController.text.trim(),
              _motivoController.text.trim(),
            ));
          },
          child: Text(context.t('common.send')),
        ),
      ],
    );
  }
}
