import 'package:flutter/material.dart';
import 'package:lookup_flutter/Postulacion/views/CrearPostulacion.dart';
import 'package:lookup_flutter/Postulacion/views/DetallePostulacion.dart';
import 'package:lookup_flutter/Postulacion/views/EditarPostulacion.dart';

class Postulacion extends StatefulWidget {
  const Postulacion({super.key});

  @override
  State<Postulacion> createState() => _PostulacionState();
}

class _PostulacionState extends State<Postulacion> {
  final List<Map<String, dynamic>> ofertas = [
    {"titulo": "Desarrollador Senior de Software", "estado": "Activa"},
    {"titulo": "Diseñador de Producto UI/UX", "estado": "En Pausa"},
    {"titulo": "Gerente de Proyectos Digitales", "estado": "Cerrada"},
    {"titulo": "Analista de Datos Jr.", "estado": "Activa"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Gestión de Ofertas',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ofertas.length,
        itemBuilder: (context, index) {
          final oferta = ofertas[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetallePostulacion(oferta: oferta),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.04),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          oferta["titulo"],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "LookUp",
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              color: oferta["estado"] == "Activa"
                                  ? Colors.green
                                  : oferta["estado"] == "En Pausa"
                                      ? Colors.orange
                                      : Colors.red,
                              size: 8,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              oferta["estado"],
                              style: TextStyle(
                                fontSize: 13,
                                color: oferta["estado"] == "Activa"
                                    ? Colors.green
                                    : oferta["estado"] == "En Pausa"
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.edit_outlined, color: Colors.blue),
                        tooltip: "Editar postulación",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditarPostulacion(oferta: oferta),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        tooltip: "Eliminar postulación",
                        onPressed: () {
                          setState(() {
                            ofertas.removeAt(index);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Postulación eliminada'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CrearPostulacion()),
          );
        },
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}
