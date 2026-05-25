import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/profile_service.dart';
import 'package:lookup_flutter/services/auth_service.dart';

class EditarPerfil extends StatefulWidget {
  const EditarPerfil({super.key});

  @override
  State<EditarPerfil> createState() => _EditarPerfilState();
}

class _EditarPerfilState extends State<EditarPerfil> {
  final _formKey = GlobalKey<FormState>();
  final _habilidadesController = TextEditingController();

  List<Map<String, dynamic>> _experiencias = [];
  List<Map<String, dynamic>> _educacion = [];
  List<String> _habilidades = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    final profileData = Provider.of<ProfileService>(context, listen: false).profileData;
    if (profileData != null) {
      _experiencias = List<Map<String, dynamic>>.from(profileData['experiencias'] ?? []);
      _educacion = List<Map<String, dynamic>>.from(profileData['educacion'] ?? []);
      _habilidades = List<String>.from(profileData['habilidades'] ?? []);
      _habilidadesController.text = _habilidades.join(', ');
    }
  }

  @override
  void dispose() {
    _habilidadesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil Profesional'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveProfile,
            tooltip: 'Guardar Perfil',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección Experiencia Laboral
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Experiencia Laboral',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_experiencias.isEmpty)
                        Text(
                          'Aún no tienes experiencias registradas',
                          style: TextStyle(color: Colors.grey[600]),
                        )
                      else
                        Column(
                          children: _experiencias.asMap().entries.map((entry) {
                            int index = entry.key;
                            var exp = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: ListTile(
                                leading: Icon(Icons.work, color: Colors.blue[600]),
                                title: Text(exp['puesto'] ?? 'Sin título'),
                                subtitle: Text(exp['empresa'] ?? 'Empresa desconocida'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeExperiencia(index),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Añadir Experiencia'),
                        onPressed: _isLoading ? null : _mostrarDialogoExperiencia,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sección Educación
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Educación',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_educacion.isEmpty)
                        Text(
                          'Aún no tienes educación registrada',
                          style: TextStyle(color: Colors.grey[600]),
                        )
                      else
                        Column(
                          children: _educacion.asMap().entries.map((entry) {
                            int index = entry.key;
                            var edu = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: ListTile(
                                leading: Icon(Icons.school, color: Colors.teal[600]),
                                title: Text(edu['titulo'] ?? 'Sin título'),
                                subtitle: Text(edu['institucion'] ?? 'Institución desconocida'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeEducacion(index),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Añadir Educación'),
                        onPressed: _isLoading ? null : _mostrarDialogoEducacion,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sección Habilidades
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Habilidades',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _habilidadesController,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Habilidades (separadas por coma)',
                          hintText: 'Ej: Flutter, Dart, UI/UX Design',
                          prefixIcon: const Icon(Icons.star),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, ingresa al menos una habilidad';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_habilidades.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children: _habilidades.map((habilidad) {
                            return Chip(
                              label: Text(habilidad),
                              onDeleted: () {
                                setState(() {
                                  _habilidades.remove(habilidad);
                                  _habilidadesController.text = _habilidades.join(', ');
                                });
                              },
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Botón Guardar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isLoading ? 'Guardando...' : 'Guardar Cambios'),
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoExperiencia() {
    final puestoController = TextEditingController();
    final empresaController = TextEditingController();
    final descripcionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir Experiencia'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: puestoController,
                decoration: InputDecoration(
                  labelText: 'Puesto',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: empresaController,
                decoration: InputDecoration(
                  labelText: 'Empresa',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descripcionController,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (puestoController.text.isNotEmpty &&
                  empresaController.text.isNotEmpty) {
                setState(() {
                  _experiencias.add({
                    'puesto': puestoController.text,
                    'empresa': empresaController.text,
                    'descripcion': descripcionController.text,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEducacion() {
    final tituloController = TextEditingController();
    final institucionController = TextEditingController();
    final fechaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir Educación'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloController,
                decoration: InputDecoration(
                  labelText: 'Título/Grado',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: institucionController,
                decoration: InputDecoration(
                  labelText: 'Institución',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fechaController,
                decoration: InputDecoration(
                  labelText: 'Año de Graduación',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (tituloController.text.isNotEmpty &&
                  institucionController.text.isNotEmpty) {
                setState(() {
                  _educacion.add({
                    'titulo': tituloController.text,
                    'institucion': institucionController.text,
                    'fecha': fechaController.text,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  void _removeExperiencia(int index) {
    setState(() {
      _experiencias.removeAt(index);
    });
  }

  void _removeEducacion(int index) {
    setState(() {
      _educacion.removeAt(index);
    });
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final profileService = Provider.of<ProfileService>(context, listen: false);

      final cuentaId = authService.cuentaId;
      if (cuentaId == null) {
        _mostrarError('Error: No se encontró la cuenta del usuario');
        return;
      }

      setState(() => _isLoading = true);

      // Procesar habilidades
      List<String> habilidades = _habilidadesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Datos a actualizar
      final profileUpdates = {
        'experiencias': _experiencias,
        'educacion': _educacion,
        'habilidades': habilidades,
      };

      // Usar el método updateProfile disponible
      bool success = await profileService.updateProfile(cuentaId, profileUpdates);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado con éxito'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      } else {
        _mostrarError('Error al actualizar el perfil. Intenta de nuevo.');
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
