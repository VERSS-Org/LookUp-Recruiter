import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/postulacion_service.dart';
import 'package:lookup_flutter/services/puesto_service.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/Postulacion/views/CrearPostulacionPage.dart';

/// Página de ejemplo para mostrar cómo integrar todos los servicios
class EjemploIntegracionPage extends StatefulWidget {
  const EjemploIntegracionPage({super.key});

  @override
  State<EjemploIntegracionPage> createState() => _EjemploIntegracionPageState();
}

class _EjemploIntegracionPageState extends State<EjemploIntegracionPage> {
  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final puestoService = Provider.of<PuestoService>(context, listen: false);
      final postulacionService =
          Provider.of<PostulacionService>(context, listen: false);

      // Cargar puestos disponibles
      puestoService.fetchAllPuestos();

      // Si el usuario está autenticado, cargar sus postulaciones
      if (authService.cuentaId != null) {
        postulacionService.fetchMisPostulaciones(authService.cuentaId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar Puestos'),
        elevation: 2,
      ),
      body: Consumer3<PuestoService, PostulacionService, AuthService>(
        builder:
            (context, puestoService, postulacionService, authService, child) {
          if (puestoService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (puestoService.puestos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No hay puestos disponibles en este momento'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: puestoService.puestos.length,
            itemBuilder: (context, index) {
              final puesto = puestoService.puestos[index];
              final yaPostulado = postulacionService.misPostulaciones.any(
                (p) => p['puesto_id'] == puesto['puesto_id'],
              );

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
                        // Encabezado
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    puesto['titulo'] ?? 'Sin título',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (puesto['empresa_id'] != null)
                                    Text(
                                      'Empresa ID: ${puesto['empresa_id']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: (puesto['estado'] == 'abierto')
                                    ? Colors.green[100]
                                    : Colors.red[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                (puesto['estado'] ?? 'desconocido')
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: (puesto['estado'] == 'abierto')
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Información de ubicación
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                puesto['ubicacion'] ?? 'No especificada',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Información de contrato
                        Row(
                          children: [
                            Icon(Icons.work, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                (puesto['tipo_contrato'] ?? 'No especificado')
                                    .toString()
                                    .replaceAll('_', ' ')
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Información de salario
                        if (puesto['salario_min'] != null ||
                            puesto['salario_max'] != null)
                          Row(
                            children: [
                              Icon(Icons.attach_money,
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _formatSalario(
                                    puesto['salario_min'],
                                    puesto['salario_max'],
                                    puesto['moneda'] ?? 'MXN',
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                        if ((puesto['salario_min'] != null ||
                            puesto['salario_max'] != null))
                          const SizedBox(height: 12),

                        // Descripción breve
                        if (puesto['descripcion'] != null)
                          Text(
                            puesto['descripcion'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Botones de acción
                        if (puesto['estado'] == 'abierto')
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: yaPostulado
                                  ? null
                                  : () => _mostrarConfirmacion(
                                        context,
                                        puesto,
                                        authService,
                                      ),
                              icon: Icon(
                                yaPostulado ? Icons.check : Icons.send,
                              ),
                              label: Text(
                                yaPostulado
                                    ? 'Ya Postulado'
                                    : 'Postularme Ahora',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    yaPostulado ? Colors.grey : Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Esta posición está cerrada',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
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

  void _mostrarConfirmacion(
    BuildContext context,
    Map<String, dynamic> puesto,
    AuthService authService,
  ) {
    if (authService.cuentaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para postularte'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CrearPostulacionPage(puesto: puesto),
      ),
    );
  }

  String _formatSalario(dynamic min, dynamic max, String moneda) {
    if (min != null && max != null) {
      return '$moneda ${min.toStringAsFixed(0)} - $moneda ${max.toStringAsFixed(0)}';
    } else if (min != null) {
      return 'Desde $moneda ${min.toStringAsFixed(0)}';
    } else if (max != null) {
      return 'Hasta $moneda ${max.toStringAsFixed(0)}';
    }
    return 'Salario no especificado';
  }
}
