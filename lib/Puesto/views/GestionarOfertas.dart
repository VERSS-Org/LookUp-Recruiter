import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/services/puesto_service.dart';
import 'package:lookup_flutter/Puesto/views/CrearPuestoPage.dart';
import 'package:lookup_flutter/Puesto/views/DetallePuestoPage.dart';

class GestionarOfertas extends StatefulWidget {
  const GestionarOfertas({super.key});

  @override
  State<GestionarOfertas> createState() => _GestionarOfertasState();
}

class _GestionarOfertasState extends State<GestionarOfertas> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final profileId = authService.profileId;
      if (profileId != null) {
        Provider.of<PuestoService>(context, listen: false)
            .fetchPuestosPorEmpresa(profileId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Ofertas'),
      ),
      body: Consumer<PuestoService>(
        builder: (context, puestoService, child) {
          if (puestoService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (puestoService.puestosEmpresa.isEmpty) {
            return const Center(
              child: Text('Aún no has publicado ninguna oferta.'),
            );
          }

          return ListView.builder(
            itemCount: puestoService.puestosEmpresa.length,
            itemBuilder: (context, index) {
              final puesto = puestoService.puestosEmpresa[index];
              return Card(
                margin: const EdgeInsets.all(10.0),
                child: ListTile(
                  title: Text(puesto['titulo'] ?? 'Sin título'),
                  subtitle: Text(puesto['ubicacion'] ?? 'Ubicación no especificada'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetallePuestoPage(puesto: puesto),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CrearPuestoPage()),
          );
        },
        label: const Text('Publicar Oferta'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
