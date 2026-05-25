import 'package:flutter/material.dart';

class Metricas extends StatefulWidget {
  const Metricas({super.key});

  @override
  State<Metricas> createState() => _MetricasState();
}

class _MetricasState extends State<Metricas> {
  final metricasEmpresa = {
    "postulaciones": 2458,
    "aceptadas": 312,
    "rechazadas": 1890,
    "activas": 12,
    "nuevas": 34,
    "pendientes": 256,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Métricas",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            const SizedBox(height: 20),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildMetricCard("Postulaciones totales recibidas",
                    metricasEmpresa["postulaciones"].toString(), Colors.blue),
                _buildMetricCard(
                    "Aceptadas", metricasEmpresa["aceptadas"].toString(), Colors.green),
                _buildMetricCard(
                    "Rechazadas", metricasEmpresa["rechazadas"].toString(), Colors.red),
                _buildMetricCard(
                    "Ofertas activas", metricasEmpresa["activas"].toString(), Colors.blueGrey),
                _buildMetricCard(
                    "Nuevas hoy", metricasEmpresa["nuevas"].toString(), Colors.black),
                _buildMetricCard("Pendientes de revisión",
                    metricasEmpresa["pendientes"].toString(), Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String titulo, String valor, Color colorValor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: colorValor,
            ),
          ),
        ],
      ),
    );
  }
}
