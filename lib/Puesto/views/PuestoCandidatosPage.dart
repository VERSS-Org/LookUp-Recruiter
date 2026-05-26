import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/postulacion_service.dart';
import 'package:lookup_flutter/services/contacto_service.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';

class PuestoCandidatosPage extends StatefulWidget {
  final dynamic puesto;
  const PuestoCandidatosPage({super.key, required this.puesto});

  @override
  State<PuestoCandidatosPage> createState() => _PuestoCandidatosPageState();
}

class _PuestoCandidatosPageState extends State<PuestoCandidatosPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    await Provider.of<PostulacionService>(context, listen: false)
        .fetchPostulacionesPorPuesto(widget.puesto['puesto_id']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Candidatos - ${widget.puesto['titulo']}')),
      body: Consumer3<PostulacionService, AuthService, ContactoService>(
        builder:
            (context, postulacionService, authService, contactoService, child) {
          if (postulacionService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (postulacionService.postulacionesPuesto.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 56, 18, 28),
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay candidatos aun',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800, color: kInk),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Los postulantes interesados apareceran aqui.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              itemCount: postulacionService.postulacionesPuesto.length,
              itemBuilder: (context, index) {
                final postulacion =
                    postulacionService.postulacionesPuesto[index];
                final estadoActual = _canonicalEstado(
                    (postulacion['estado'] ?? 'pendiente').toString());
                final estadosDisponibles = _estadoOptions(estadoActual);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: kBrandBlue.withOpacity(0.1),
                              child: const Icon(Icons.person_outline,
                                  color: kBrandBlue),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    postulacion['candidato']
                                            ?['nombre_completo'] ??
                                        postulacion['candidato_id']
                                            ?.toString() ??
                                        'Candidato',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: kInk,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (postulacion['candidato']?['email'] !=
                                      null)
                                    Text(
                                      postulacion['candidato']['email'],
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700),
                                    ),
                                ],
                              ),
                            ),
                            _buildEstadoBadge(estadoActual),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _InfoLine(
                          icon: Icons.calendar_today_outlined,
                          text:
                              'Postulado: ${_formatDate(postulacion['fecha_postulacion'])}',
                        ),
                        if (postulacion['documentos_adjuntos'] != null &&
                            (postulacion['documentos_adjuntos'] as List)
                                .isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _InfoLine(
                            icon: Icons.attach_file,
                            text:
                                'Documentos: ${(postulacion['documentos_adjuntos'] as List).length}',
                          ),
                        ],
                        if (postulacion['hitos'] != null &&
                            (postulacion['hitos'] as List).isNotEmpty) ...[
                          const Divider(height: 24),
                          const Text('Ultimos eventos',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, color: kInk)),
                          const SizedBox(height: 8),
                          ...(postulacion['hitos'] as List).take(2).map((hito) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _InfoLine(
                                icon: Icons.radio_button_checked,
                                text: hito['descripcion'] ?? 'Evento',
                              ),
                            );
                          }),
                        ],
                        const Divider(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: estadoActual,
                                decoration: const InputDecoration(
                                  labelText: 'Estado',
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                items: estadosDisponibles.map((value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(_estadoLabel(value),
                                        style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  if (newValue != null &&
                                      newValue != estadoActual) {
                                    _cambiarEstado(
                                        context,
                                        postulacion['postulacion_id'],
                                        newValue);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton.filledTonal(
                              tooltip: 'Abrir contacto',
                              icon: const Icon(Icons.forum_outlined),
                              onPressed: () {
                                _mostrarDialogoContacto(context, postulacion,
                                    authService, contactoService);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _canonicalEstado(String estado) =>
      estado == 'rechazo' ? 'rechazado' : estado;

  List<String> _estadoOptions(String estado) {
    const transitions = <String, List<String>>{
      'pendiente': [
        'pendiente',
        'en_revision',
        'entrevista',
        'aceptado',
        'oferta',
        'rechazado'
      ],
      'en_revision': [
        'en_revision',
        'entrevista',
        'aceptado',
        'oferta',
        'rechazado'
      ],
      'entrevista': ['entrevista', 'aceptado', 'oferta', 'rechazado'],
      'aceptado': ['aceptado', 'entrevista', 'oferta', 'rechazado'],
      'oferta': ['oferta'],
      'rechazado': ['rechazado'],
    };

    return transitions[estado] ?? <String>[estado];
  }

  String _estadoLabel(String estado) {
    const labels = {
      'pendiente': 'PENDIENTE',
      'en_revision': 'EN REVISION',
      'entrevista': 'ENTREVISTA',
      'aceptado': 'ACEPTADO',
      'oferta': 'OFERTA',
      'rechazado': 'RECHAZADO',
    };
    return labels[estado] ?? estado.replaceAll('_', ' ').toUpperCase();
  }

  Widget _buildEstadoBadge(String estado) {
    late Color color;
    late IconData icon;

    switch (estado) {
      case 'pendiente':
        color = Colors.orange;
        icon = Icons.schedule;
        break;
      case 'en_revision':
        color = kBrandBlue;
        icon = Icons.visibility_outlined;
        break;
      case 'entrevista':
        color = kSkyBlue;
        icon = Icons.videocam_outlined;
        break;
      case 'oferta':
        color = Colors.teal;
        icon = Icons.card_giftcard;
        break;
      case 'aceptado':
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case 'rechazado':
        color = Colors.redAccent;
        icon = Icons.cancel_outlined;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(
            _estadoLabel(estado),
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  Future<void> _cambiarEstado(
      BuildContext context, String postulacionId, String nuevoEstado) async {
    final postulacionService =
        Provider.of<PostulacionService>(context, listen: false);
    final puestoId = widget.puesto['puesto_id'];

    final success = await postulacionService.updateEstadoPostulacion(
        postulacionId, nuevoEstado, puestoId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Estado actualizado a: ${_estadoLabel(nuevoEstado)}'
            : 'Error al actualizar el estado'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _mostrarDialogoContacto(
    BuildContext context,
    dynamic postulacion,
    AuthService authService,
    ContactoService contactoService,
  ) {
    showDialog(
      context: context,
      builder: (context) => _ContactoDialog(
        postulacion: postulacion,
        authService: authService,
        contactoService: contactoService,
        puestoId: widget.puesto['puesto_id'],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Recientemente';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) return 'Hace ${difference.inMinutes} min';
        return 'Hace ${difference.inHours}h';
      }
      if (difference.inDays == 1) return 'Ayer';
      if (difference.inDays < 7) return 'Hace ${difference.inDays} dias';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'Recientemente';
    }
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: kBrandBlue),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800))),
      ],
    );
  }
}

class _ContactoDialog extends StatefulWidget {
  final dynamic postulacion;
  final AuthService authService;
  final ContactoService contactoService;
  final String puestoId;

  const _ContactoDialog({
    required this.postulacion,
    required this.authService,
    required this.contactoService,
    required this.puestoId,
  });

  @override
  State<_ContactoDialog> createState() => _ContactoDialogState();
}

class _ContactoDialogState extends State<_ContactoDialog> {
  final _mensajeController = TextEditingController();
  final _motivoController = TextEditingController();
  String _tipoFeedback = 'comentario';
  bool _isLoading = true;
  bool _isSending = false;
  List<dynamic> _mensajes = const <dynamic>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMessages());
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final mensajes = await widget.contactoService
        .fetchContactos(widget.postulacion['postulacion_id']);
    if (!mounted) return;
    setState(() {
      _mensajes = mensajes;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final candidato =
        widget.postulacion['candidato']?['nombre_completo'] ?? 'Candidato';
    final dialogWidth = MediaQuery.of(context).size.width > 620
        ? 540.0
        : MediaQuery.of(context).size.width * 0.88;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      title: Row(
        children: [
          const Icon(Icons.forum_outlined, color: kBrandBlue),
          const SizedBox(width: 10),
          Expanded(
              child: Text('Contacto con $candidato',
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
        height: 500,
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _mensajes.isEmpty
                      ? Center(
                          child: Text(
                            'Aun no hay mensajes para esta postulacion.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _mensajes.length,
                          itemBuilder: (context, index) =>
                              _MessageBubble(contacto: _mensajes[index]),
                        ),
            ),
            const Divider(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _tipoFeedback,
              decoration: const InputDecoration(labelText: 'Tipo de mensaje'),
              items: const [
                DropdownMenuItem(
                    value: 'comentario', child: Text('Comentario')),
                DropdownMenuItem(
                    value: 'aprobacion', child: Text('Aprobacion')),
                DropdownMenuItem(value: 'rechazo', child: Text('Rechazo')),
                DropdownMenuItem(value: 'otro', child: Text('Otro')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _tipoFeedback = value);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _mensajeController,
              decoration: const InputDecoration(
                labelText: 'Mensaje',
                hintText: 'Escribe una actualizacion para el postulante',
              ),
              minLines: 2,
              maxLines: 3,
            ),
            if (_tipoFeedback == 'rechazo') ...[
              const SizedBox(height: 10),
              TextField(
                controller: _motivoController,
                decoration: const InputDecoration(
                  labelText: 'Motivo del rechazo',
                  hintText: 'Indica el motivo para cerrar el proceso',
                ),
                minLines: 1,
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _isSending ? null : () => Navigator.pop(context),
            child: const Text('Cerrar')),
        FilledButton.icon(
          onPressed: _isSending ? null : _enviarMensaje,
          icon: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send_outlined),
          label: const Text('Enviar'),
        ),
      ],
    );
  }

  Future<void> _enviarMensaje() async {
    if (_mensajeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un mensaje antes de enviar')),
      );
      return;
    }

    if (_tipoFeedback == 'rechazo' && _motivoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica el motivo del rechazo')),
      );
      return;
    }

    final candidato = widget.postulacion['candidato'];
    final candidatoId = candidato is Map
        ? candidato['cuenta_id']?.toString()
        : widget.postulacion['candidato_id']?.toString();

    if (candidatoId == null ||
        candidatoId.isEmpty ||
        widget.authService.cuentaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar al postulante')),
      );
      return;
    }

    setState(() => _isSending = true);
    final success = await widget.contactoService.enviarFeedback(
      postulacionId: widget.postulacion['postulacion_id'],
      empresaId: widget.authService.cuentaId!,
      cuentaId: candidatoId,
      tipoFeedback: _tipoFeedback,
      mensajeTexto: _mensajeController.text.trim(),
      motivoRechazo:
          _tipoFeedback == 'rechazo' ? _motivoController.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _isSending = false);

    if (success) {
      _mensajeController.clear();
      _motivoController.clear();
      await _loadMessages();
      if (!mounted) return;
      await Provider.of<PostulacionService>(context, listen: false)
          .fetchPostulacionesPorPuesto(widget.puestoId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Mensaje enviado'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              widget.contactoService.errorMessage ?? 'Error al enviar mensaje'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.contacto});

  final dynamic contacto;

  @override
  Widget build(BuildContext context) {
    final feedback = contacto is Map ? contacto['ultimo_feedback'] : null;
    final feedbackMap = feedback is Map ? feedback : const <String, dynamic>{};
    final tipo = feedbackMap['tipo']?.toString() ?? 'comentario';
    final mensaje = feedbackMap['mensaje']?.toString() ??
        'La empresa envio una actualizacion.';
    final motivo = feedbackMap['motivo_rechazo']?.toString();
    final fecha = contacto is Map ? contacto['fecha_hora']?.toString() : null;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: MediaQuery.of(context).size.width > 620 ? 420 : null,
        margin: const EdgeInsets.only(bottom: 10, left: 36),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kBrandBlue.withOpacity(0.08),
          border: Border.all(color: kBrandBlue.withOpacity(0.16)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
            bottomLeft: Radius.circular(8),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_tipoLabel(tipo),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: kBrandBlue)),
                const Spacer(),
                if (fecha != null)
                  Text(_shortDate(fecha),
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 6),
            Text(mensaje, style: const TextStyle(color: kInk)),
            if (motivo != null && motivo.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Motivo: $motivo',
                  style: TextStyle(
                      color: Colors.grey.shade800,
                      fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }

  String _tipoLabel(String tipo) {
    const labels = {
      'comentario': 'COMENTARIO',
      'aprobacion': 'APROBACION',
      'rechazo': 'RECHAZO',
      'otro': 'OTRO',
    };
    return labels[tipo] ?? tipo.toUpperCase();
  }

  String _shortDate(String raw) {
    try {
      final date = DateTime.parse(raw);
      return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
