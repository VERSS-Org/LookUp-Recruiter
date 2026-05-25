import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/postulacion_service.dart';
import 'package:lookup_flutter/services/contacto_service.dart';
import 'package:lookup_flutter/services/auth_service.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PostulacionService>(context, listen: false)
          .fetchPostulacionesPorPuesto(widget.puesto['puesto_id']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Candidatos - ${widget.puesto['titulo']}'),
        elevation: 2,
      ),
      body: Consumer3<PostulacionService, AuthService, ContactoService>(
        builder: (context, postulacionService, authService, contactoService, child) {
          if (postulacionService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (postulacionService.postulacionesPuesto.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay candidatos aún',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Los candidatos interesados aparecerán aquí',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: postulacionService.postulacionesPuesto.length,
            itemBuilder: (context, index) {
              final postulacion = postulacionService.postulacionesPuesto[index];
              final estadoActual = (postulacion['estado'] ?? 'pendiente').toString();
              final estadosDisponibles = _estadoOptions(estadoActual);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado con nombre y estado
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    postulacion['candidato']?['nombre_completo'] ??
                                    postulacion['candidato_id']?.toString() ?? 'Candidato',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (postulacion['candidato']?['email'] != null)
                                    Text(
                                      postulacion['candidato']['email'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            _buildEstadoBadge(estadoActual),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Información de fecha
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Postulado: ${_formatDate(postulacion['fecha_postulacion'])}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Documentos adjuntos
                        if (postulacion['documentos_adjuntos'] != null &&
                            (postulacion['documentos_adjuntos'] as List).isNotEmpty)
                          Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.attach_file, size: 16, color: Colors.blue[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Documentos: ${(postulacion['documentos_adjuntos'] as List).length}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),

                        // Hitos/Progreso
                        if (postulacion['hitos'] != null &&
                            (postulacion['hitos'] as List).isNotEmpty)
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Últimos Eventos',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Column(
                                      children: (postulacion['hitos'] as List)
                                          .take(2)
                                          .map<Widget>((hito) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 6.0),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: Colors.blue,
                                                  borderRadius: BorderRadius.circular(3),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  hito['descripcion'] ?? 'Evento',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[700],
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),

                        // Selector de estado y acciones
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: estadoActual,
                                  underline: const SizedBox(),
                                  items: estadosDisponibles.map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value.replaceAll('_', ' ').toUpperCase(),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null && newValue != estadoActual) {
                                      _cambiarEstado(
                                        context,
                                        postulacion['postulacion_id'],
                                        newValue,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              tooltip: 'Enviar feedback',
                              icon: const Icon(Icons.message),
                              onPressed: () {
                                _mostrarDialogoFeedback(
                                  context,
                                  postulacion,
                                  authService,
                                  contactoService,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Widget para mostrar el badge de estado
  List<String> _estadoOptions(String estado) {
    const transitions = <String, List<String>>{
      'pendiente': ['pendiente', 'en_revision', 'entrevista', 'aceptado', 'oferta', 'rechazado', 'rechazo'],
      'en_revision': ['en_revision', 'entrevista', 'aceptado', 'oferta', 'rechazado', 'rechazo'],
      'entrevista': ['entrevista', 'aceptado', 'oferta', 'rechazado', 'rechazo'],
      'aceptado': ['aceptado', 'entrevista', 'oferta', 'rechazado', 'rechazo'],
      'oferta': ['oferta'],
      'rechazado': ['rechazado'],
      'rechazo': ['rechazo'],
    };

    return transitions[estado] ?? <String>[estado];
  }

  Widget _buildEstadoBadge(String estado) {
    Color color;
    IconData icon;

    switch (estado) {
      case 'pendiente':
        color = Colors.orange;
        icon = Icons.schedule;
        break;
      case 'en_revision':
        color = Colors.blue;
        icon = Icons.visibility;
        break;
      case 'entrevista':
        color = Colors.purple;
        icon = Icons.videocam;
        break;
      case 'oferta':
        color = Colors.teal;
        icon = Icons.card_giftcard;
        break;
      case 'aceptado':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'rechazado':
      case 'rechazo':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            estado.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Cambiar estado de la postulación
  void _cambiarEstado(BuildContext context, String postulacionId, String nuevoEstado) async {
    final postulacionService = Provider.of<PostulacionService>(context, listen: false);
    final puestoId = widget.puesto['puesto_id'];

    final success = await postulacionService.updateEstadoPostulacion(
      postulacionId,
      nuevoEstado,
      puestoId,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a: $nuevoEstado'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar el estado'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Mostrar diálogo para enviar feedback
  void _mostrarDialogoFeedback(
    BuildContext context,
    dynamic postulacion,
    AuthService authService,
    ContactoService contactoService,
  ) {
    showDialog(
      context: context,
      builder: (context) => _FeedbackDialog(
        postulacion: postulacion,
        authService: authService,
        contactoService: contactoService,
        puestoId: widget.puesto['puesto_id'],
      ),
    );
  }

  /// Formatea fecha a formato legible
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Recientemente';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return 'Hace ${difference.inMinutes} min';
        }
        return 'Hace ${difference.inHours}h';
      } else if (difference.inDays == 1) {
        return 'Ayer';
      } else if (difference.inDays < 7) {
        return 'Hace ${difference.inDays} días';
      }
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Recientemente';
    }
  }
}

/// Diálogo para enviar feedback
class _FeedbackDialog extends StatefulWidget {
  final dynamic postulacion;
  final AuthService authService;
  final ContactoService contactoService;
  final String puestoId;

  const _FeedbackDialog({
    required this.postulacion,
    required this.authService,
    required this.contactoService,
    required this.puestoId,
  });

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  late String _tipoFeedback;
  final _mensajeController = TextEditingController();
  final _motivoController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tipoFeedback = 'comentario';
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enviar Feedback'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _tipoFeedback,
              decoration: InputDecoration(
                labelText: 'Tipo de Feedback',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: <String>['aprobacion', 'rechazo', 'comentario', 'otro']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value.toUpperCase()),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _tipoFeedback = newValue);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _mensajeController,
              decoration: InputDecoration(
                labelText: 'Mensaje',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Escribe tu mensaje...',
              ),
              maxLines: 3,
            ),
            if (_tipoFeedback == 'rechazo') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _motivoController,
                decoration: InputDecoration(
                  labelText: 'Motivo del Rechazo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Explica por qué no fue seleccionado...',
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _enviarFeedback,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enviar'),
        ),
      ],
    );
  }

  void _enviarFeedback() async {
    if (_mensajeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor escribe un mensaje')),
      );
      return;
    }

    final candidato = widget.postulacion['candidato'];
    final candidatoId = candidato is Map
        ? candidato['cuenta_id']?.toString()
        : widget.postulacion['candidato_id']?.toString();

    if (candidatoId == null || candidatoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar al postulante')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await widget.contactoService.enviarFeedback(
      postulacionId: widget.postulacion['postulacion_id'],
      empresaId: widget.authService.cuentaId!,
      cuentaId: candidatoId,
      tipoFeedback: _tipoFeedback,
      mensajeTexto: _mensajeController.text,
      motivoRechazo: _tipoFeedback == 'rechazo' ? _motivoController.text : null,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback enviado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.contactoService.errorMessage ?? 'Error al enviar'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
