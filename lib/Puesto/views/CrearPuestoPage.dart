import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/puesto_service.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';

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
  bool _isSubmitting = false;

  final List<String> _ciudadesPeru = [
    'Lima',
    'Arequipa',
    'Trujillo',
    'Chiclayo',
    'Piura',
    'Cusco',
    'Huancayo',
    'Iquitos',
    'Tacna',
    'Chimbote',
    'Pucallpa',
    'Juliaca',
    'Ica',
    'Cajamarca',
    'Sullana',
    'Ayacucho',
    'Chincha',
    'Huanuco',
    'Huaraz',
    'Puno',
  ];

  final Map<String, String> _tiposContrato = {
    'tiempo_completo': 'Tiempo Completo',
    'medio_tiempo': 'Medio Tiempo',
    'temporal': 'Temporal',
    'freelance': 'Freelance',
    'practicas': 'Practicas',
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
      appBar: AppBar(title: const Text('Crear Nuevo Puesto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: kBrandBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.work_outline, color: kBrandBlue),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Publica una oferta clara para atraer postulantes compatibles.',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, color: kInk),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Titulo del puesto',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Campo requerido'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripcion',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLines: 5,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Campo requerido'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(
                  labelText: 'Direccion exacta (opcional)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCiudad,
                decoration: const InputDecoration(labelText: 'Ciudad'),
                items: _ciudadesPeru.map((ciudad) {
                  return DropdownMenuItem<String>(
                    value: ciudad,
                    child: Text(ciudad),
                  );
                }).toList(),
                onChanged: (newValue) =>
                    setState(() => _selectedCiudad = newValue),
                validator: (value) =>
                    value == null ? 'Por favor, selecciona una ciudad' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedTipoContrato,
                decoration:
                    const InputDecoration(labelText: 'Tipo de Contrato'),
                items: _tiposContrato.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (newValue) =>
                    setState(() => _selectedTipoContrato = newValue),
                validator: (value) => value == null
                    ? 'Por favor, selecciona un tipo de contrato'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _salarioMinController,
                decoration: const InputDecoration(
                  labelText: 'Salario minimo',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: _validateSalary,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _salarioMaxController,
                decoration: const InputDecoration(
                  labelText: 'Salario maximo',
                  prefixIcon: Icon(Icons.payments),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final salaryError = _validateSalary(value);
                  if (salaryError != null) return salaryError;
                  final min =
                      double.tryParse(_salarioMinController.text.trim());
                  final max = double.tryParse(value?.trim() ?? '');
                  if (min != null && max != null && max < min) {
                    return 'El maximo no puede ser menor al minimo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitForm,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.publish_outlined),
                  label:
                      Text(_isSubmitting ? 'Publicando...' : 'Publicar puesto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateSalary(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final parsed = double.tryParse(trimmed);
    if (parsed == null) return 'Ingresa un numero valido';
    if (parsed < 0) return 'El salario no puede ser negativo';
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final puestoService = Provider.of<PuestoService>(context, listen: false);
    final empresaId = authService.cuentaId;

    if (empresaId == null || empresaId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se encontro la sesion de empresa'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final direccion = _direccionController.text.trim();
    final ubicacionCompleta =
        direccion.isEmpty ? _selectedCiudad! : '$direccion, $_selectedCiudad';

    setState(() => _isSubmitting = true);
    final success = await puestoService.crearPuesto(
      empresaId: empresaId,
      titulo: _tituloController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      ubicacion: ubicacionCompleta,
      tipoContrato: _selectedTipoContrato!,
      salarioMin: double.tryParse(_salarioMinController.text.trim()),
      salarioMax: double.tryParse(_salarioMaxController.text.trim()),
      moneda: 'PEN',
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Puesto publicado con exito'),
            backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(puestoService.errorMessage ?? 'Error al publicar el puesto'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
