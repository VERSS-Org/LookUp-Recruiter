import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/puesto_service.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/Puesto/views/PuestoForm.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';
import 'package:lookup_flutter/theme/lookup_widgets.dart';

/// Pantalla para publicar una nueva vacante.
class CrearPuestoPage extends StatelessWidget {
  const CrearPuestoPage({super.key});

  Future<bool> _crear(BuildContext context, PuestoFormData data) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final puestoService = Provider.of<PuestoService>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final danger = context.colors.danger;
    final empresaId = authService.cuentaId;

    if (empresaId == null || empresaId.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.tr('common.session.missing')),
          backgroundColor: danger,
        ),
      );
      return false;
    }

    final success = await puestoService.crearPuesto(
      empresaId: empresaId,
      titulo: data.titulo,
      descripcion: data.descripcion,
      ubicacion: data.ubicacion,
      tipoContrato: data.tipoContrato,
      salarioMin: data.salarioMin,
      salarioMax: data.salarioMax,
      moneda: data.moneda,
      requisitos: data.requisitos.isEmpty ? null : data.requisitos,
    );

    if (success) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('jobs.published.ok'))),
      );
      navigator.pop(true);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            puestoService.errorMessage ?? context.tr('jobs.publish.error'),
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
      appBar: AppBar(title: Text(context.t('jobs.publish'))),
      body: ViewportScrollPage(
        maxWidth: 760,
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.t('jobs.new.title'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              context.t('jobs.new.subtitle'),
              style: TextStyle(color: c.inkMuted, fontSize: 14.5),
            ),
            const SizedBox(height: 20),
            PuestoForm(
              submitLabel: context.t('jobs.publish'),
              submittingLabel: context.t('jobs.publishing'),
              onSubmit: (data) => _crear(context, data),
            ),
          ],
        ),
      ),
    );
  }
}
