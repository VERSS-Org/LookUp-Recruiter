import 'package:flutter/material.dart';
import 'package:lookup_flutter/Postulacion/views/ListaPostulantes.dart';

class DetallePostulacion extends StatelessWidget {
  final Map<String, dynamic> oferta;

  const DetallePostulacion({super.key, required this.oferta});

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
          oferta["titulo"],
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,

      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Innovatech Solutions Inc.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                oferta["titulo"],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Santiago, Chile (Híbrido)",
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(Icons.work_outline, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    "Jornada Completa",
                    style: TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                ],
              ),
              const Divider(height: 30, thickness: 1, color: Color(0xFFE5E5E5)),

              const Text(
                "Descripción del Puesto",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Buscamos un Diseñador UX/UI Senior apasionado por liderar el diseño de nuestras nuevas aplicaciones móviles. "
                    "Serás responsable de todo el proceso de diseño, desde la investigación de usuarios hasta la creación de prototipos "
                    "interactivos y la entrega de diseños finales de alta fidelidad.",
                style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 20),

              const Text(
                "Requisitos del Puesto",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Experiencia demostrable de más de 5 años en diseño UX/UI para aplicaciones móviles. "
                    "Dominio de herramientas como Figma, Sketch y Adobe XD. "
                    "Sólido portafolio con proyectos que muestren tu proceso de diseño y el impacto en el producto final. "
                    "Habilidades de comunicación y trabajo en equipo.",
                style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 30),

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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ListaPostulantes(),
                      ),
                    );
                  },
                  child: const Text(
                    "Ver Postulantes de esta Oferta",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
