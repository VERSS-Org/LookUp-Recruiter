import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/postulacion_service.dart';
import 'package:lookup_flutter/services/auth_service.dart';

class CrearPostulacionPage extends StatefulWidget {
  final Map<String, dynamic> puesto;

  const CrearPostulacionPage({super.key, required this.puesto});

  @override
  State<CrearPostulacionPage> createState() => _CrearPostulacionPageState();
}

class _CrearPostulacionPageState extends State<CrearPostulacionPage> {
  @override
  Widget build(BuildContext context) {
    final postulacionService = Provider.of<PostulacionService>(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Postulación'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con instrucción
            const Text(
              'Detalles de la Postulación',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Revisa la información antes de confirmar tu postulación',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Card principal con detalles del puesto
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título del puesto
                    Text(
                      widget.puesto['titulo'] ?? 'Sin título',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Información del puesto en filas
                    _buildInfoRow(
                      icon: Icons.location_on,
                      label: 'Ubicación',
                      value: widget.puesto['ubicacion'] ?? 'No especificada',
                    ),
                    const SizedBox(height: 12),

                    _buildInfoRow(
                      icon: Icons.work,
                      label: 'Tipo de Contrato',
                      value:
                          (widget.puesto['tipo_contrato'] ?? 'No especificado')
                              .toString()
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                    ),
                    const SizedBox(height: 12),

                    // Información de salario si está disponible
                    if (widget.puesto['salario_min'] != null ||
                        widget.puesto['salario_max'] != null)
                      Column(
                        children: [
                          _buildInfoRow(
                            icon: Icons.attach_money,
                            label: 'Salario',
                            value: _formatSalario(
                              widget.puesto['salario_min'],
                              widget.puesto['salario_max'],
                              widget.puesto['moneda'] ?? 'MXN',
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),

                    // Descripción del puesto
                    if (widget.puesto['descripcion'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Descripción',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.puesto['descripcion'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Card de confirmación
            Card(
              elevation: 2,
              color: Colors.blue[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.blue[200]!, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Asegúrate de que tu perfil esté completo antes de confirmar.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Botones de acción
            postulacionService.isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final success =
                                await postulacionService.applyForJob(
                              authService.cuentaId!,
                              widget.puesto['puesto_id'],
                            );

                            if (!mounted) return;

                            if (success) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('¡Postulación exitosa!'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst);
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      postulacionService.errorMessage ??
                                          'Error al postular.',
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text(
                            'Confirmar Postulación',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.cancel),
                          label: const Text(
                            'Cancelar',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[400]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  /// Widget para mostrar información en filas
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Formatea el rango de salario
  String _formatSalario(dynamic min, dynamic max, String moneda) {
    if (min != null && max != null) {
      return '$moneda ${min.toStringAsFixed(0)} - $moneda ${max.toStringAsFixed(0)}';
    } else if (min != null) {
      return 'Desde $moneda ${min.toStringAsFixed(0)}';
    } else if (max != null) {
      return 'Hasta $moneda ${max.toStringAsFixed(0)}';
    }
    return 'No especificado';
  }
}
