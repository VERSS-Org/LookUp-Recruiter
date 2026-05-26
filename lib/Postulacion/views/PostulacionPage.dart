import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/postulacion_service.dart';
import 'package:lookup_flutter/Postulacion/views/PuestoDetailPage.dart';

class PostulacionPage extends StatefulWidget {
  const PostulacionPage({super.key});

  @override
  State<PostulacionPage> createState() => _PostulacionPageState();
}

class _PostulacionPageState extends State<PostulacionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PostulacionService>(context, listen: false).fetchPuestos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final postulacionService = Provider.of<PostulacionService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ofertas de Trabajo'),
      ),
      body: postulacionService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : postulacionService.puestos.isEmpty
              ? const Center(child: Text('No se encontraron ofertas.'))
              : ListView.builder(
                  itemCount: postulacionService.puestos.length,
                  itemBuilder: (context, index) {
                    final puesto = postulacionService.puestos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(puesto['titulo'] ?? 'Sin título'),
                        subtitle: Text(puesto['ubicacion'] ?? 'Sin ubicación'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PuestoDetailPage(puesto: puesto),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
