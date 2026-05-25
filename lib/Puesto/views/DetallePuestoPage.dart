import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/puesto_service.dart';
import 'package:lookup_flutter/Puesto/views/PuestoCandidatosPage.dart';

class DetallePuestoPage extends StatefulWidget {
  final Map<String, dynamic> puesto;

  const DetallePuestoPage({super.key, required this.puesto});

  @override
  State<DetallePuestoPage> createState() => _DetallePuestoPageState();
}

class _DetallePuestoPageState extends State<DetallePuestoPage> {
  late Future<Map<String, dynamic>?> _puestoDetailFuture;

  @override
  void initState() {
    super.initState();
    _refreshPuestoDetails();
  }

  void _refreshPuestoDetails() {
    final puestoId = widget.puesto['puesto_id'] ?? widget.puesto['id'];
    if (puestoId != null) {
      setState(() {
        _puestoDetailFuture = Provider.of<PuestoService>(context, listen: false)
            .getPuestoDetails(puestoId.toString());
      });
    } else {
      _puestoDetailFuture = Future.value(null);
    }
  }

  Future<void> _cambiarEstado(Map<String, dynamic> puesto) async {
    final currentState = puesto['estado']?.toString() ?? 'abierto';
    final newState = currentState == 'abierto' ? 'cerrado' : 'abierto';
    
    final puestoId = (puesto['puesto_id'] ?? puesto['id'])?.toString();
    final empresaId = puesto['empresa'] is Map
        ? puesto['empresa']['id']?.toString()
        : puesto['empresa_id']?.toString();

    if (puestoId == null || empresaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo identificar el puesto o la empresa.')),
      );
      return;
    }

    final dialogTitle = Text(newState == 'cerrado' ? 'Confirmar Cierre de Oferta' : 'Confirmar Reapertura de Oferta');
    final dialogContent = Text(newState == 'cerrado'
        ? '¿Estás seguro de que quieres cerrar esta oferta? Los usuarios ya no podrán postularse ni verla.'
        : '¿Estás seguro de que quieres reabrir esta oferta? Volverá a estar visible para los usuarios.');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: dialogTitle,
          content: dialogContent,
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final puestoService = Provider.of<PuestoService>(context, listen: false);
      final success = await puestoService.cambiarEstadoPuesto(puestoId, newState, empresaId);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('El estado del puesto ha sido actualizado a "$newState".')),
          );
          _refreshPuestoDetails();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(puestoService.errorMessage ?? 'Ocurrió un error al cambiar el estado.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.puesto['titulo'] ?? 'Detalle de la Oferta'),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _puestoDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar detalles: ${snapshot.error}'));
          }
          
          final fetchedPuesto = snapshot.data;
          final displayPuesto = Map<String, dynamic>.from(widget.puesto);

          if (fetchedPuesto != null) {
            fetchedPuesto.forEach((key, value) {
              if (key == 'empresa' && value == null) return;
              displayPuesto[key] = value;
            });
          }

          final bool isAbierto = displayPuesto['estado'] == 'abierto';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (displayPuesto['empresa'] != null && displayPuesto['empresa'] is Map)
                          Text(
                            displayPuesto['empresa']['nombre'] ?? 'Empresa no disponible',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 24.0),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                (displayPuesto['ubicacion'] != null && displayPuesto['ubicacion'].toString().isNotEmpty)
                                    ? displayPuesto['ubicacion'].toString()
                                    : 'Ubicación no disponible',
                                style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            if (displayPuesto['tipo_contrato'] != null && displayPuesto['tipo_contrato'].toString().isNotEmpty)
                              Chip(
                                avatar: const Icon(Icons.work_outline, size: 16),
                                label: Text(
                                  () {
                                    final tipo = displayPuesto['tipo_contrato'].toString();
                                    if (tipo == 'tiempo_completo') {
                                      return 'Tiempo Completo';
                                    } else if (tipo == 'medio_tiempo') {
                                      return 'Medio Tiempo';
                                    }
                                    return tipo;
                                  }(),
                                ),
                              ),
                            if (displayPuesto['salario_min'] != null || displayPuesto['salario_max'] != null)
                              Chip(
                                avatar: const Icon(Icons.attach_money, size: 16),
                                label: Text(
                                    "\$${displayPuesto['salario_min'] ?? 0} - \$${displayPuesto['salario_max'] ?? 0}"),
                              ),
                            if (displayPuesto['estado'] != null)
                              Chip(
                                avatar: const Icon(Icons.info_outline, size: 16),
                                label: SizedBox(
                                  width: 90,
                                  child: Center(child: Text(displayPuesto['estado'])),
                                ),
                                backgroundColor: isAbierto ? Colors.green[100] : Colors.red[300],
                              ),
                            if (displayPuesto['fecha_publicacion'] != null)
                              Chip(
                                avatar: const Icon(Icons.calendar_today, size: 16),
                                label: SizedBox(
                                  width: 90,
                                  child: Center(
                                    child: Text(
                                      (() {
                                        try {
                                          final date = DateTime.parse(displayPuesto['fecha_publicacion']);
                                          return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
                                        } catch (e) {
                                          return displayPuesto['fecha_publicacion'].toString().split('T')[0];
                                        }
                                      })(),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                if (displayPuesto['estado'] != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _cambiarEstado(displayPuesto),
                      icon: Icon(isAbierto ? Icons.lock_outline : Icons.lock_open_outlined),
                      label: Text(isAbierto ? 'Cerrar Oferta' : 'Reabrir Oferta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAbierto ? Colors.redAccent : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                const SizedBox(height: 16.0),
                const Text(
                  'Descripción del Puesto',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Text(displayPuesto['descripcion'] ?? 'No hay descripción disponible.'),
                if (displayPuesto['requisitos'] != null && (displayPuesto['requisitos'] as List).isNotEmpty) ...[
                  const SizedBox(height: 16.0),
                  const Text(
                    'Requisitos',
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  ...(displayPuesto['requisitos'] as List).map((req) {
                    String textoReq = '';
                    if (req is Map) {
                      textoReq = req['descripcion'] ?? '';
                    } else {
                      textoReq = req.toString();
                    }
                    return ListTile(
                      leading: const Icon(Icons.check_circle_outline, size: 20),
                      title: Text(textoReq),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PuestoCandidatosPage(puesto: widget.puesto),
              ),
            );
          },
          child: const Text('Ver Postulantes de esta Oferta'),
        ),
      ),
    );
  }
}
