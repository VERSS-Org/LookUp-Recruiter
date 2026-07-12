import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Enlaces entre los portales de LookUp.
///
/// Producción debe definir `LOOKUP_USER_PORTAL_URL` durante el build. El valor
/// por defecto solo facilita el desarrollo local y evita fijar un dominio que
/// todavía no forma parte de la configuración del proyecto.
class PortalLinks {
  PortalLinks._();

  static const applicantPortalUrl = String.fromEnvironment(
    'LOOKUP_USER_PORTAL_URL',
    defaultValue: 'http://localhost:8095',
  );

  static Future<bool> openApplicantPortal() async {
    final uri = Uri.tryParse(applicantPortalUrl);
    final scheme = uri?.scheme.toLowerCase();
    if (uri == null ||
        !uri.hasAuthority ||
        (scheme != 'http' && scheme != 'https')) {
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Future<void> openApplicantPortal(
  BuildContext context, {
  required String errorMessage,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    if (await PortalLinks.openApplicantPortal()) return;
  } catch (_) {
    // El mensaje visible de abajo cubre navegadores que bloquean la apertura.
  }
  if (context.mounted) {
    messenger.showSnackBar(
      SnackBar(content: Text(errorMessage)),
    );
  }
}
