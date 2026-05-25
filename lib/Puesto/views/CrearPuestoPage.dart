import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/puesto_service.dart';
import 'package:lookup_flutter/services/auth_service.dart';

class CrearPuestoPage extends StatefulWidget {
  const CrearPuestoPage({super.key});

  @override
  State<CrearPuestoPage> createState() => _CrearPuestoPageState();
}

class _CrearPuestoPageState extends State<CrearPuestoPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _direccionController = TextEditingController();
  final _salarioMinController = TextEditingController();
  final _salarioMaxController = TextEditingController();
  String? _selectedCiudad;
  String? _selectedTipoContrato;

  final List<String> _ciudadesPeru = [
    'Lima', 'Arequipa', 'Trujillo', 'Chiclayo', 'Piura', 'Cusco', 
    'Huancayo', 'Iquitos', 'Tacna', 'Chimbote', 'Pucallpa', 'Juliaca', 
    'Ica', 'Cajamarca', 'Sullana', 'Ayacucho', 'Chincha', 'Huánuco', 
    'Huaraz', 'Puno'
  ];

  final Map<String, String> _tiposContrato = {
    'tiempo_completo': 'Tiempo Completo',
    'medio_tiempo': 'Medio Tiempo',
  };

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _direccionController.dispose();
    _salarioMinController.dispose();
    _salarioMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nuevo Puesto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título del puesto'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 5,
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(labelText: 'Dirección exacta (Opcional)'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _selectedCiudad,
                decoration: const InputDecoration(labelText: 'Ciudad'),
                items: _ciudadesPeru.map((String ciudad) {
                  return DropdownMenuItem<String>(
                    value: ciudad,
                    child: Text(ciudad),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCiudad = newValue;
                  });
                },
                validator: (value) => value == null ? 'Por favor, selecciona una ciudad' : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: _selectedTipoContrato,
                decoration: const InputDecoration(labelText: 'Tipo de Contrato'),
                items: _tiposContrato.entries.map((MapEntry<String, String> entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedTipoContrato = newValue;
                  });
                },
                validator: (value) => value == null ? 'Por favor, selecciona un tipo de contrato' : null,
              ),
              TextFormField(
                controller: _salarioMinController,
                decoration: const InputDecoration(labelText: 'Salario Mínimo'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _salarioMaxController,
                decoration: const InputDecoration(labelText: 'Salario Máximo'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Publicar Puesto'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final puestoService = Provider.of<PuestoService>(context, listen: false);

      String ubicacionCompleta;
      if (_direccionController.text.isNotEmpty) {
        ubicacionCompleta = "${_direccionController.text}, $_selectedCiudad";
      } else {
        ubicacionCompleta = _selectedCiudad!;
      }

      bool success = await puestoService.crearPuesto(
        empresaId: authService.profileId!.toString(),
        titulo: _tituloController.text,
        descripcion: _descripcionController.text,
        ubicacion: ubicacionCompleta,
        tipoContrato: _selectedTipoContrato!,
        salarioMin: double.tryParse(_salarioMinController.text),
        salarioMax: double.tryParse(_salarioMaxController.text),
        moneda: 'EUR',
      );

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Puesto publicado con éxito')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al publicar el puesto')),
        );
      }
    }
  }
}
