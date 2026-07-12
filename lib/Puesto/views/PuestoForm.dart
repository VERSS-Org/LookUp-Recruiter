import 'package:flutter/material.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';

/// Datos que produce el formulario de puesto al enviarse.
class PuestoFormData {
  const PuestoFormData({
    required this.titulo,
    required this.descripcion,
    required this.ubicacion,
    required this.tipoContrato,
    required this.moneda,
    this.salarioMin,
    this.salarioMax,
    required this.requisitos,
  });

  final String titulo;
  final String descripcion;
  final String ubicacion;
  final String tipoContrato;
  final String moneda;
  final double? salarioMin;
  final double? salarioMax;
  final List<Map<String, dynamic>> requisitos;
}

/// Formulario reutilizable para crear o editar una vacante.
class PuestoForm extends StatefulWidget {
  const PuestoForm({
    super.key,
    this.initial,
    required this.submitLabel,
    required this.submittingLabel,
    required this.onSubmit,
  });

  /// Puesto existente para precargar los campos (modo edicion).
  final Map<String, dynamic>? initial;
  final String submitLabel;
  final String submittingLabel;
  final Future<bool> Function(PuestoFormData data) onSubmit;

  static const List<String> ciudadesPeru = [
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

  static const List<String> monedas = ['PEN', 'USD', 'EUR'];

  static const Map<String, String> tiposContrato = {
    'tiempo_completo': 'Tiempo completo',
    'medio_tiempo': 'Medio tiempo',
    'temporal': 'Temporal',
    'freelance': 'Freelance',
    'practicas': 'Prácticas',
  };

  @override
  State<PuestoForm> createState() => _PuestoFormState();
}

class _PuestoFormState extends State<PuestoForm> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _direccionController = TextEditingController();
  final _salarioMinController = TextEditingController();
  final _salarioMaxController = TextEditingController();
  final _requisitoController = TextEditingController();
  String? _selectedCiudad;
  String? _selectedTipoContrato;
  String _selectedMoneda = 'PEN';
  bool _requisitoObligatorio = true;
  bool _isSubmitting = false;
  final List<Map<String, dynamic>> _requisitos = [];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _tituloController.text = initial['titulo']?.toString() ?? '';
      _descripcionController.text = initial['descripcion']?.toString() ?? '';
      _selectedTipoContrato = initial['tipo_contrato']?.toString();
      if (!PuestoForm.tiposContrato.containsKey(_selectedTipoContrato)) {
        _selectedTipoContrato = null;
      }
      final moneda = initial['moneda']?.toString();
      if (moneda != null && PuestoForm.monedas.contains(moneda)) {
        _selectedMoneda = moneda;
      }
      _prefillUbicacion(initial['ubicacion']?.toString() ?? '');
      _prefillSalario(_salarioMinController, initial['salario_min']);
      _prefillSalario(_salarioMaxController, initial['salario_max']);
      for (final req in (initial['requisitos'] as List?) ?? const []) {
        if (req is Map && (req['descripcion']?.toString() ?? '').isNotEmpty) {
          _requisitos.add({
            'tipo': req['tipo']?.toString() ?? 'habilidad',
            'descripcion': req['descripcion'].toString(),
            'es_obligatorio': req['es_obligatorio'] != false,
          });
        }
      }
    }
  }

  /// La ubicacion se guarda como "direccion, Ciudad" o solo "Ciudad".
  void _prefillUbicacion(String ubicacion) {
    if (ubicacion.isEmpty) return;
    final partes = ubicacion.split(',').map((p) => p.trim()).toList();
    final ciudad = partes.last;
    if (PuestoForm.ciudadesPeru.contains(ciudad)) {
      _selectedCiudad = ciudad;
      _direccionController.text =
          partes.sublist(0, partes.length - 1).join(', ');
    } else {
      _direccionController.text = ubicacion;
    }
  }

  void _prefillSalario(TextEditingController controller, dynamic value) {
    if (value == null) return;
    final numero = value is num
        ? value.toDouble()
        : double.tryParse(value.toString().replaceAll(',', '.'));
    if (numero == null) return;
    controller.text = numero == numero.roundToDouble()
        ? numero.toInt().toString()
        : numero.toString();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _direccionController.dispose();
    _salarioMinController.dispose();
    _salarioMaxController.dispose();
    _requisitoController.dispose();
    super.dispose();
  }

  String? _validateSalary(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final parsed = _parseSalary(trimmed);
    if (parsed == null) return context.tr('form.salary.invalid');
    if (parsed < 0) return context.tr('form.salary.negative');
    return null;
  }

  double? _parseSalary(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  void _agregarRequisito() {
    final texto = _requisitoController.text.trim();
    if (texto.isEmpty) return;
    setState(() {
      _requisitos.add({
        'tipo': 'habilidad',
        'descripcion': texto,
        'es_obligatorio': _requisitoObligatorio,
      });
      _requisitoController.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final direccion = _direccionController.text.trim();
    final ubicacion =
        direccion.isEmpty ? _selectedCiudad! : '$direccion, $_selectedCiudad';

    setState(() => _isSubmitting = true);
    final ok = await widget.onSubmit(
      PuestoFormData(
        titulo: _tituloController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        ubicacion: ubicacion,
        tipoContrato: _selectedTipoContrato!,
        moneda: _selectedMoneda,
        salarioMin: _parseSalary(_salarioMinController.text),
        salarioMax: _parseSalary(_salarioMaxController.text),
        requisitos: List<Map<String, dynamic>>.from(_requisitos),
      ),
    );
    if (mounted && !ok) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.t('form.data'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.colors.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tituloController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: context.t('form.title'),
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? context.tr('form.required')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descripcionController,
                    decoration: InputDecoration(
                      labelText: context.t('form.description'),
                      alignLabelWithHint: true,
                      prefixIcon: const Icon(Icons.notes_outlined),
                    ),
                    minLines: 4,
                    maxLines: 7,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? context.tr('form.required')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 620;
                      final cityField = DropdownButtonFormField<String>(
                        initialValue: _selectedCiudad,
                        decoration: InputDecoration(
                          labelText: context.t('form.city'),
                          prefixIcon: const Icon(Icons.location_city_outlined),
                        ),
                        items: PuestoForm.ciudadesPeru.map((ciudad) {
                          return DropdownMenuItem<String>(
                            value: ciudad,
                            child: Text(ciudad),
                          );
                        }).toList(),
                        onChanged: (newValue) =>
                            setState(() => _selectedCiudad = newValue),
                        validator: (value) => value == null
                            ? context.tr('form.city.required')
                            : null,
                      );
                      final contractField = DropdownButtonFormField<String>(
                        initialValue: _selectedTipoContrato,
                        decoration: InputDecoration(
                          labelText: context.t('form.contract'),
                          prefixIcon: const Icon(Icons.assignment_outlined),
                        ),
                        items: PuestoForm.tiposContrato.keys.map((tipo) {
                          return DropdownMenuItem<String>(
                            value: tipo,
                            child: Text(context.t('contrato.$tipo')),
                          );
                        }).toList(),
                        onChanged: (newValue) =>
                            setState(() => _selectedTipoContrato = newValue),
                        validator: (value) => value == null
                            ? context.tr('form.contract.required')
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
                    decoration: InputDecoration(
                      labelText: context.t('form.address'),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 620;
                      final currencyField = DropdownButtonFormField<String>(
                        initialValue: _selectedMoneda,
                        decoration: InputDecoration(
                          labelText: context.tr('form.currency'),
                          prefixIcon:
                              const Icon(Icons.currency_exchange_outlined),
                        ),
                        items: PuestoForm.monedas.map((moneda) {
                          return DropdownMenuItem<String>(
                            value: moneda,
                            child: Text(moneda),
                          );
                        }).toList(),
                        onChanged: (newValue) => setState(
                          () => _selectedMoneda = newValue ?? 'PEN',
                        ),
                      );
                      final minField = TextFormField(
                        controller: _salarioMinController,
                        decoration: InputDecoration(
                          labelText: context.tr('form.salary_min'),
                          prefixIcon: const Icon(Icons.payments_outlined),
                          suffixText: _selectedMoneda,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _validateSalary,
                      );
                      final maxField = TextFormField(
                        controller: _salarioMaxController,
                        decoration: InputDecoration(
                          labelText: context.tr('form.salary_max'),
                          prefixIcon: const Icon(Icons.payments),
                          suffixText: _selectedMoneda,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          final salaryError = _validateSalary(value);
                          if (salaryError != null) return salaryError;
                          final min = _parseSalary(_salarioMinController.text);
                          final max = _parseSalary(value ?? '');
                          if (min != null && max != null && max < min) {
                            return context.tr('form.salary.order');
                          }
                          return null;
                        },
                      );

                      if (!isWide) {
                        return Column(
                          children: [
                            currencyField,
                            const SizedBox(height: 12),
                            minField,
                            const SizedBox(height: 12),
                            maxField,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 130, child: currencyField),
                          const SizedBox(width: 12),
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
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.t('form.requirements'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.colors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.t('form.requirements.hint'),
                    style: TextStyle(
                      color: context.colors.inkMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _requisitoController,
                          decoration: InputDecoration(
                            labelText: context.t('form.requirement.example'),
                            prefixIcon: const Icon(Icons.playlist_add_check),
                          ),
                          onFieldSubmitted: (_) => _agregarRequisito(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        tooltip: context.t('common.add'),
                        onPressed: _agregarRequisito,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _requisitoObligatorio,
                        onChanged: (value) => setState(
                          () => _requisitoObligatorio = value ?? true,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          context.t('form.requirement.mandatory'),
                          style: TextStyle(
                            color: context.colors.ink,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_requisitos.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < _requisitos.length; i++)
                          Chip(
                            avatar: Icon(
                              _requisitos[i]['es_obligatorio'] == true
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              size: 18,
                              color: context.colors.brand,
                            ),
                            label: Text(
                              _requisitos[i]['descripcion'].toString(),
                            ),
                            onDeleted: () =>
                                setState(() => _requisitos.removeAt(i)),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.publish_outlined),
            label: Text(
              _isSubmitting ? widget.submittingLabel : widget.submitLabel,
            ),
          ),
        ],
      ),
    );
  }
}
