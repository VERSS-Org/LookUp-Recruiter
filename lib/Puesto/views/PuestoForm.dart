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
    this.onCancel,
  });

  /// Puesto existente para precargar los campos (modo edicion).
  final Map<String, dynamic>? initial;
  final String submitLabel;
  final String submittingLabel;
  final Future<bool> Function(PuestoFormData data) onSubmit;
  final VoidCallback? onCancel;

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

  /// Valores aceptados por la API. La etiqueta visible se resuelve desde
  /// `contrato.<valor>` para mantener el selector traducible.
  static const List<String> tiposContrato = [
    'tiempo_completo',
    'medio_tiempo',
    'practicas',
    'temporal',
  ];

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
      if (!PuestoForm.tiposContrato.contains(_selectedTipoContrato)) {
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
          _FormSectionTitle(text: context.t('form.data')),
          const SizedBox(height: 14),
          _FormFieldLabel(text: context.t('form.title')),
          const SizedBox(height: 6),
          TextFormField(
            controller: _tituloController,
            textInputAction: TextInputAction.next,
            validator: (value) => value == null || value.trim().isEmpty
                ? context.tr('form.required')
                : null,
          ),
          const SizedBox(height: 13),
          _FormFieldLabel(text: context.t('form.description')),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descripcionController,
            minLines: 4,
            maxLines: 7,
            validator: (value) => value == null || value.trim().isEmpty
                ? context.tr('form.required')
                : null,
          ),
          const SizedBox(height: 13),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 560;
              final city = _LabeledField(
                label: context.t('form.city'),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCiudad,
                  isExpanded: true,
                  items: [
                    for (final city in PuestoForm.ciudadesPeru)
                      DropdownMenuItem(value: city, child: Text(city)),
                  ],
                  onChanged: (value) => setState(() => _selectedCiudad = value),
                  validator: (value) =>
                      value == null ? context.tr('form.city.required') : null,
                ),
              );
              final contract = _LabeledField(
                label: context.t('form.contract'),
                child: DropdownButtonFormField<String>(
                  key: const ValueKey('vacancy-contract-field'),
                  initialValue: _selectedTipoContrato,
                  isExpanded: true,
                  items: [
                    for (final type in PuestoForm.tiposContrato)
                      DropdownMenuItem(
                        value: type,
                        child: Text(context.t('contrato.$type')),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedTipoContrato = value),
                  validator: (value) => value == null
                      ? context.tr('form.contract.required')
                      : null,
                ),
              );
              if (!wide) {
                return Column(
                  children: [city, const SizedBox(height: 13), contract],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: city),
                  const SizedBox(width: 12),
                  Expanded(child: contract),
                ],
              );
            },
          ),
          const SizedBox(height: 13),
          _FormFieldLabel(text: context.t('form.address')),
          const SizedBox(height: 6),
          TextFormField(
            controller: _direccionController,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 13),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 620;
              final currency = _LabeledField(
                label: context.t('form.currency'),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedMoneda,
                  items: [
                    for (final currency in PuestoForm.monedas)
                      DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedMoneda = value ?? 'PEN'),
                ),
              );
              final minimum = _LabeledField(
                label: context.t('form.salary_min'),
                child: TextFormField(
                  controller: _salarioMinController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: _validateSalary,
                ),
              );
              final maximum = _LabeledField(
                label: context.t('form.salary_max'),
                child: TextFormField(
                  controller: _salarioMaxController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    final salaryError = _validateSalary(value);
                    if (salaryError != null) return salaryError;
                    final min = _parseSalary(_salarioMinController.text);
                    final max = _parseSalary(value ?? '');
                    return min != null && max != null && max < min
                        ? context.tr('form.salary.order')
                        : null;
                  },
                ),
              );
              if (!wide) {
                return Column(
                  children: [
                    currency,
                    const SizedBox(height: 13),
                    minimum,
                    const SizedBox(height: 13),
                    maximum,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 120, child: currency),
                  const SizedBox(width: 12),
                  Expanded(child: minimum),
                  const SizedBox(width: 12),
                  Expanded(child: maximum),
                ],
              );
            },
          ),
          const SizedBox(height: 26),
          Divider(color: context.colors.border),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FormSectionTitle(
                  text: context.t('form.requirements'),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  context.t('form.requirements.hint'),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: context.colors.inkFaint,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 620;
              final field = TextFormField(
                controller: _requisitoController,
                decoration: InputDecoration(
                  hintText: context.t('form.requirement.example'),
                ),
                onFieldSubmitted: (_) => _agregarRequisito(),
              );
              final toggle = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: _requisitoObligatorio,
                    onChanged: (value) =>
                        setState(() => _requisitoObligatorio = value),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    context.t('form.requirement.required'),
                    style: TextStyle(
                      color: context.colors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
              final add = OutlinedButton.icon(
                onPressed: _agregarRequisito,
                icon: const Icon(Icons.add, size: 16),
                label: Text(context.t('common.add')),
              );
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    field,
                    const SizedBox(height: 8),
                    Row(
                      children: [Expanded(child: toggle), add],
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: field),
                  const SizedBox(width: 10),
                  toggle,
                  const SizedBox(width: 10),
                  add,
                ],
              );
            },
          ),
          if (_requisitos.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (var index = 0; index < _requisitos.length; index++)
              _RequirementRow(
                requirement: _requisitos[index],
                onDelete: () => setState(() => _requisitos.removeAt(index)),
              ),
          ],
          const SizedBox(height: 26),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 440;
              final cancel = OutlinedButton(
                onPressed: _isSubmitting
                    ? null
                    : widget.onCancel ?? () => Navigator.maybePop(context),
                child: Text(context.t('common.cancel')),
              );
              final submit = FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.publish_outlined, size: 17),
                label: Text(
                  _isSubmitting ? widget.submittingLabel : widget.submitLabel,
                ),
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [submit, const SizedBox(height: 8), cancel],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [cancel, const SizedBox(width: 10), submit],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FormSectionTitle extends StatelessWidget {
  const _FormSectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}

class _FormFieldLabel extends StatelessWidget {
  const _FormFieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.colors.ink,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FormFieldLabel(text: label),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({
    required this.requirement,
    required this.onDelete,
  });

  final Map<String, dynamic> requirement;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mandatory = requirement['es_obligatorio'] == true;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Icon(
            mandatory ? Icons.check_circle : Icons.check_circle_outline,
            size: 16,
            color: mandatory ? c.brand : c.inkFaint,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              requirement['descripcion']?.toString() ?? '',
              style: TextStyle(color: c.ink, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: c.surfaceAlt,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              context.t(
                mandatory ? 'form.requirement.required' : 'jobs.desirable',
              ),
              style: TextStyle(color: c.inkMuted, fontSize: 9.5),
            ),
          ),
          IconButton(
            tooltip: context.t('common.delete'),
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 17),
          ),
        ],
      ),
    );
  }
}
