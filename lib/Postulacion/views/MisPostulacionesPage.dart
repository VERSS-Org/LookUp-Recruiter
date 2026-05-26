import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/services/postulacion_service.dart';

class MisPostulacionesPage extends StatefulWidget {
  const MisPostulacionesPage({super.key});

  @override
  State<MisPostulacionesPage> createState() => _MisPostulacionesPageState();
}

class _MisPostulacionesPageState extends State<MisPostulacionesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final profileId = authService.profileId;
      if (profileId != null) {
        Provider.of<PostulacionService>(context, listen: false)
            .fetchMisPostulaciones(profileId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Postulaciones'),
      ),
      body: Consumer<PostulacionService>(
        builder: (context, postulacionService, child) {
          if (postulacionService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (postulacionService.misPostulaciones.isEmpty) {
            return const Center(
              child: Text('Aún no has realizado ninguna postulación.'),
            );
          }

          return ListView.builder(
            itemCount: postulacionService.misPostulaciones.length,
            itemBuilder: (context, index) {
              final postulacion = postulacionService.misPostulaciones[index];
              return Card(
                margin: const EdgeInsets.all(10.0),
                child: ListTile(
                  title: Text(postulacion['puesto']?['titulo'] ?? 'Sin título'),
                  subtitle:
                      Text(postulacion['empresa']?['nombre'] ?? 'Sin empresa'),
                  trailing: Chip(
                    label: Text(
                      postulacion['estado'] ?? 'desconocido',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: _getStatusColor(postulacion['estado']),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String? estado) {
    switch (estado) {
      case 'en_revision':
        return Colors.orange;
      case 'entrevista':
        return Colors.green;
      case 'rechazado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
