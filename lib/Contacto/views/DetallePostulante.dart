import 'package:flutter/material.dart';
import 'package:lookup_flutter/Postulacion/views/ListaPostulantes.dart';
import 'package:lookup_flutter/Postulacion/views/DatosPostulante.dart';
import 'package:lookup_flutter/Postulacion/views/MetricasPostulante.dart';

class DetallePostulante extends StatefulWidget {
  final Map<String, dynamic> postulante;

  const DetallePostulante({super.key, required this.postulante});

  @override
  State<DetallePostulante> createState() => _DetallePostulanteState();
}

class _DetallePostulanteState extends State<DetallePostulante> {
  String estadoSeleccionado = "";
  final TextEditingController feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    estadoSeleccionado = widget.postulante["estado"];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.postulante["nombre"],
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Información del Postulante",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _buildInfoButton(
              context,
              "Ver Datos de Postulación",
              Icons.description_outlined,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DatosPostulante(postulante: widget.postulante),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            _buildInfoButton(
              context,
              "Ver Métricas del Postulante",
              Icons.bar_chart_outlined,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MetricasPostulante(postulante: widget.postulante),
                  ),
                );
              },
            ),

            const SizedBox(height: 25),

            const Text(
              "Gestión de Estado",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildEstadoSelector(),

            const SizedBox(height: 25),

            const Text(
              "Envío de Feedback",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: feedbackController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Escribe tus comentarios aquí...",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Postulante actualizado: Estado "$estadoSeleccionado" | Feedback: "${feedbackController.text}"',
                      ),
                    ),
                  );

                  // Luego de actualizar, volvemos a la lista
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ListaPostulantes()),
                  );

                },
                child: const Text(
                  "Actualizar Postulante",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoButton(
      BuildContext context, String text, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoSelector() {
    final estados = ["Entrevista", "Pendiente", "En revisión", "Logrado", "Rechazo"];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: estados
            .map((estado) => RadioListTile<String>(
          title: Text(estado),
          value: estado,
          groupValue: estadoSeleccionado,
          activeColor: Colors.blue,
          onChanged: (value) => setState(() => estadoSeleccionado = value!),
        ))
            .toList(),
      ),
    );
  }
}
