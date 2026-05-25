import 'package:flutter/material.dart';
import 'package:lookup_flutter/Contacto/views/DetallePostulante.dart';

class ListaPostulantes extends StatefulWidget {
  const ListaPostulantes({super.key});

  @override
  State<ListaPostulantes> createState() => _ListaPostulantesState();
}

class _ListaPostulantesState extends State<ListaPostulantes> {
  final List<Map<String, dynamic>> postulantes = [
    {
      "nombre": "Alejandra Martínez",
      "estado": "Entrevista",
      "imagen": "https://cdn-icons-png.flaticon.com/512/4140/4140048.png"
    },
    {
      "nombre": "Benjamín Carter",
      "estado": "En revisión",
      "imagen": "https://cdn-icons-png.flaticon.com/512/4140/4140037.png"
    },
    {
      "nombre": "Isabella Rossi",
      "estado": "Oferta",
      "imagen": "https://cdn-icons-png.flaticon.com/512/4140/4140051.png"
    },
    {
      "nombre": "Carlos Mendoza",
      "estado": "Rechazo",
      "imagen": "https://cdn-icons-png.flaticon.com/512/4140/4140061.png"
    },
    {
      "nombre": "Sofía Navarro",
      "estado": "Pendiente",
      "imagen": "https://cdn-icons-png.flaticon.com/512/4140/4140086.png"
    },
  ];

  String filtroSeleccionado = "Ver Todos";

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> postulantesFiltrados =
    filtroSeleccionado == "Ver Todos"
        ? postulantes
        : postulantes
        .where((p) => p["estado"] == filtroSeleccionado)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:
          const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Postulantes",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          const SizedBox(height: 10),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                _buildFiltro("Pendiente"),
                _buildFiltro("En revisión"),
                _buildFiltro("Entrevista"),
                _buildFiltro("Oferta"),
                _buildFiltro("Rechazo"),
                _buildFiltro("Ver Todos"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: postulantesFiltrados.length,
              itemBuilder: (context, index) {
                final postulante = postulantesFiltrados[index];
                return _buildPostulanteCard(context, postulante);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltro(String texto) {
    final bool seleccionado = filtroSeleccionado == texto;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          texto,
          style: TextStyle(
            color: seleccionado ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        selected: seleccionado,
        selectedColor: Colors.blue[700],
        backgroundColor: Colors.grey[200],
        onSelected: (_) => setState(() => filtroSeleccionado = texto),
      ),
    );
  }

  Widget _buildPostulanteCard(
      BuildContext context, Map<String, dynamic> postulante) {
    Color colorEstado;
    switch (postulante["estado"]) {
      case "Pendiente":
        colorEstado = Colors.grey;
        break;
      case "En revisión":
        colorEstado = Colors.orange;
        break;
      case "Entrevista":
        colorEstado = Colors.blue;
        break;
      case "Oferta":
        colorEstado = Colors.green;
        break;
      case "Rechazo":
        colorEstado = Colors.red;
        break;
      default:
        colorEstado = Colors.black54;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: NetworkImage(postulante["imagen"]),
        ),
        title: Text(
          postulante["nombre"],
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        subtitle: Text(
          postulante["estado"],
          style: TextStyle(fontSize: 13, color: colorEstado),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetallePostulante(postulante: postulante),
            ),
          );
        },
      ),
    );
  }
}
