import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/metricas_service.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';

class MetricasPage extends StatefulWidget {
  const MetricasPage({super.key});

  @override
  State<MetricasPage> createState() => _MetricasPageState();
}

class _MetricasPageState extends State<MetricasPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final metricasService =
          Provider.of<MetricasService>(context, listen: false);

      if (authService.cuentaId != null) {
        metricasService.fetchMetricasResumen(authService.cuentaId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final metricasService = Provider.of<MetricasService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Métricas'),
        elevation: 2,
      ),
      body: metricasService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección de Resumen de Métricas
                  const Text(
                    'Resumen de Actividad',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: kInk,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tu progreso en la búsqueda de empleo',
                    style: TextStyle(fontSize: 13.5, color: kInkMuted),
                  ),
                  const SizedBox(height: 18),

                  // Grid de métricas principales
                  if (metricasService.metricasResumen != null)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.2,
                      children: [
                        _buildMetricCard(
                          title: 'Postulaciones',
                          value: metricasService
                              .metricasResumen!['total_postulaciones']
                              .toString(),
                          icon: Icons.send,
                          color: Colors.blue,
                        ),
                        _buildMetricCard(
                          title: 'Entrevistas',
                          value: metricasService
                              .metricasResumen!['total_entrevistas']
                              .toString(),
                          icon: Icons.videocam,
                          color: Colors.orange,
                        ),
                        _buildMetricCard(
                          title: 'Éxitos',
                          value: metricasService
                              .metricasResumen!['total_exitos']
                              .toString(),
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                        _buildMetricCard(
                          title: 'Rechazos',
                          value: metricasService
                              .metricasResumen!['total_rechazos']
                              .toString(),
                          icon: Icons.close,
                          color: Colors.red,
                        ),
                      ],
                    )
                  else
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            'No hay datos de métricas disponibles',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  /// Widget para tarjeta de métrica individual
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: softShadow(),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: kInk,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: kInkMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
