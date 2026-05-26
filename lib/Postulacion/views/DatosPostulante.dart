import 'package:flutter/material.dart';

class DatosPostulante extends StatelessWidget {
  final Map<String, dynamic> postulante;

  const DatosPostulante({super.key, required this.postulante});

  @override
  Widget build(BuildContext context) {
    final datos = {
      "nombre": postulante["nombre"] ?? "Alejandra Martínez",
      "carrera": "Diseño Gráfico",
      "universidad": "Universidad de Buenos Aires",
      "experiencia": "5 años",
      "telefono": "+54 9 11 1234-5678",
      "correo": "alejandra.martinez@email.com",
      "ciudad": "Buenos Aires, Argentina",
      "disponibilidad": "Inmediata",
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Datos del Postulante",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard([
              _buildItem("Nombre completo", datos["nombre"]),
              _buildItem("Carrera", datos["carrera"]),
              _buildItem("Universidad", datos["universidad"]),
              _buildItem("Años de experiencia", datos["experiencia"]),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard([
              _buildItem("Teléfono", datos["telefono"]),
              _buildItem("Correo electrónico", datos["correo"]),
              _buildItem("Ciudad", datos["ciudad"]),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard([
              _buildItem("Disponibilidad", datos["disponibilidad"]),
            ]),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Descargando CV (demo)..."),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text(
                  "Descargar CV",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildItem(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
