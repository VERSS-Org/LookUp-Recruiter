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
      appBar: AppBar(title: const Text('Publicar puesto')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: kBrandGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: softShadow(opacity: 0.25, blur: 28, y: 14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                          child:
                              const Icon(Icons.work_outline, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nueva oferta',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Publica un puesto claro y listo para recibir candidatos.',
                                style: TextStyle(
                                  color: Colors.white,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Datos del puesto',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: kInk,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _tituloController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Titulo del puesto',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
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
                            minLines: 4,
                            maxLines: 7,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Campo requerido'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 620;
                              final cityField = DropdownButtonFormField<String>(
                                initialValue: _selectedCiudad,
                                decoration: const InputDecoration(
                                  labelText: 'Ciudad',
                                  prefixIcon: Icon(Icons.location_city_outlined),
                                ),
                                items: _ciudadesPeru.map((ciudad) {
                                  return DropdownMenuItem<String>(
                                    value: ciudad,
                                    child: Text(ciudad),
                                  );
                                }).toList(),
                                onChanged: (newValue) =>
                                    setState(() => _selectedCiudad = newValue),
                                validator: (value) => value == null
                                    ? 'Selecciona una ciudad'
                                    : null,
                              );
                              final contractField =
                                  DropdownButtonFormField<String>(
                                initialValue: _selectedTipoContrato,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo de contrato',
                                  prefixIcon: Icon(Icons.assignment_outlined),
                                ),
                                items: _tiposContrato.entries.map((entry) {
                                  return DropdownMenuItem<String>(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  );
                                }).toList(),
                                onChanged: (newValue) => setState(
                                    () => _selectedTipoContrato = newValue),
                                validator: (value) => value == null
                                    ? 'Selecciona un tipo de contrato'
                                    : null,
                              );

                              if (!isWide) {
                                return Column(
                                  children: [
                                    cityField,
                                    const SizedBox(height: 12),
                                    contractField,
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: cityField),
                                  const SizedBox(width: 12),
                                  Expanded(child: contractField),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _direccionController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Direccion exacta (opcional)',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 620;
                              final minField = TextFormField(
                                controller: _salarioMinController,
                                decoration: const InputDecoration(
                                  labelText: 'Salario minimo',
                                  prefixIcon: Icon(Icons.payments_outlined),
                                  suffixText: 'PEN',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: _validateSalary,
                              );
                              final maxField = TextFormField(
                                controller: _salarioMaxController,
                                decoration: const InputDecoration(
                                  labelText: 'Salario maximo',
                                  prefixIcon: Icon(Icons.payments),
                                  suffixText: 'PEN',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: (value) {
                                  final salaryError = _validateSalary(value);
                                  if (salaryError != null) return salaryError;
                                  final min =
                                      _parseSalary(_salarioMinController.text);
                                  final max = _parseSalary(value ?? '');
                                  if (min != null &&
                                      max != null &&
                                      max < min) {
                                    return 'El maximo no puede ser menor al minimo';
                                  }
                                  return null;
                                },
                              );

                              if (!isWide) {
                                return Column(
                                  children: [
                                    minField,
                                    const SizedBox(height: 12),
                                    maxField,
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: minField),
                                  const SizedBox(width: 12),
                                  Expanded(child: maxField),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitForm,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.publish_outlined),
                    label: Text(
                      _isSubmitting ? 'Publicando...' : 'Publicar puesto',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateSalary(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final parsed = _parseSalary(trimmed);
    if (parsed == null) return 'Ingresa un numero valido';
    if (parsed < 0) return 'El salario no puede ser negativo';
    return null;
  }

  double? _parseSalary(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final puestoService = Provider.of<PuestoService>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
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
      salarioMin: _parseSalary(_salarioMinController.text),
      salarioMax: _parseSalary(_salarioMaxController.text),
      moneda: 'PEN',
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Puesto publicado con exito'),
            backgroundColor: Colors.green),
      );
      navigator.pop(true);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content:
              Text(puestoService.errorMessage ?? 'Error al publicar el puesto'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
