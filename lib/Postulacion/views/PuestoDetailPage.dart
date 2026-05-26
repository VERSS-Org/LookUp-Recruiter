import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/Postulacion/views/CrearPostulacionPage.dart';

class PuestoDetailPage extends StatelessWidget {
  final Map<String, dynamic> puesto;

  const PuestoDetailPage({super.key, required this.puesto});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isPostulante = authService.role == 'postulante';

    return Scaffold(
      appBar: AppBar(
        title: Text(puesto['titulo'] ?? 'Detalle de la Oferta'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              puesto['titulo'] ?? 'Sin título',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Empresa
            if (puesto['empresa'] != null && puesto['empresa'] is Map)
              Text(
                'Empresa: ${puesto['empresa']['nombre'] ?? 'Sin empresa'}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              )
            else if (puesto['empresa_id'] != null)
              Text(
                'Empresa ID: ${puesto['empresa_id']}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),

            const SizedBox(height: 16),

            // Ubicación
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    puesto['ubicacion'] ?? 'No especificada',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tipo de contrato
            if (puesto['tipo_contrato'] != null)
              Row(
                children: [
                  const Icon(Icons.work, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Tipo: ${puesto['tipo_contrato'].toString().replaceAll('_', ' ').toUpperCase()}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            const SizedBox(height: 12),

            // Salario
            if (puesto['salario_min'] != null || puesto['salario_max'] != null)
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Salario: ${puesto['salario_min'] ?? '0'} - ${puesto['salario_max'] ?? '0'} ${puesto['moneda'] ?? 'MXN'}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Descripción
            const Text(
              'Descripción',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              puesto['descripcion'] ?? 'Sin descripción',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Botón de postulación (solo para candidatos)
            if (isPostulante)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CrearPostulacionPage(puesto: puesto),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Postularme'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Solo los candidatos pueden postularse a ofertas',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
