import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/puesto_service.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/Puesto/views/PuestoForm.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';
import 'package:lookup_flutter/theme/lookup_widgets.dart';

/// Pantalla para editar una vacante ya publicada.
class EditarPuestoPage extends StatelessWidget {
  const EditarPuestoPage({super.key, required this.puesto});

  final Map<String, dynamic> puesto;

  Future<bool> _actualizar(BuildContext context, PuestoFormData data) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final puestoService = Provider.of<PuestoService>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final danger = context.colors.danger;
    final empresaId = authService.cuentaId;
    final puestoId = (puesto['puesto_id'] ?? puesto['id'])?.toString();

    if (empresaId == null || puestoId == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.tr('jobs.identity.error')),
          backgroundColor: danger,
        ),
      );
      return false;
    }

    final success = await puestoService.actualizarPuesto(
      puestoId: puestoId,
      empresaId: empresaId,
      titulo: data.titulo,
      descripcion: data.descripcion,
      ubicacion: data.ubicacion,
      tipoContrato: data.tipoContrato,
      moneda: data.moneda,
      salarioMin: data.salarioMin,
      salarioMax: data.salarioMax,
      requisitos: data.requisitos,
    );

    if (success) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('jobs.updated.ok'))),
      );
      navigator.pop(true);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            puestoService.errorMessage ?? context.tr('jobs.update.error'),
          ),
          backgroundColor: danger,
        ),
      );
    }
    return success;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: Text(context.t('jobs.edit'))),
      body: PageContainer(
        maxWidth: 760,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                puesto['titulo']?.toString() ?? context.t('jobs.edit'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                context.t('jobs.edit.subtitle'),
                style: TextStyle(color: c.inkMuted, fontSize: 14.5),
              ),
              const SizedBox(height: 20),
              PuestoForm(
                initial: puesto,
                submitLabel: context.t('jobs.save'),
                submittingLabel: context.t('jobs.saving'),
                onSubmit: (data) => _actualizar(context, data),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
