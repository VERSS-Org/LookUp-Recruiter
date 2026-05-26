import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/services/profile_service.dart';
import 'package:lookup_flutter/Auth/views/Login.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.cuentaId != null) {
        Provider.of<ProfileService>(context, listen: false)
            .fetchProfile(authService.cuentaId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final profileService = Provider.of<ProfileService>(context);
    final profile = profileService.profileData ?? const <String, dynamic>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _showLogoutDialog(context, authService),
            tooltip: 'Cerrar sesion',
          ),
        ],
      ),
      body: profileService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 26, 18, 22),
                  decoration: BoxDecoration(
                    gradient: kBrandGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: softShadow(opacity: 0.30, blur: 28, y: 14),
                  ),
                  child: Column(
                    children: [
                      _ProfileAvatar(
                        fotoUrl: profile['foto_url']?.toString(),
                        onGradient: true,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        profile['nombre_completo']?.toString() ?? 'Usuario',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        profile['email']?.toString() ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Cambiar foto'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.7),
                            width: 1.4,
                          ),
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        onPressed: () => _showPhotoDialog(
                            context,
                            authService,
                            profileService,
                            profile['foto_url']?.toString()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                InfoCard(
                    icon: Icons.email_outlined,
                    title: 'Correo Electronico',
                    content: profile['email']?.toString() ?? 'No disponible'),
                const SizedBox(height: 12),
                InfoCard(
                    icon: Icons.business_outlined,
                    title: 'Cuenta de empresa',
                    content: 'Gestiona ofertas de trabajo y candidatos'),
                const SizedBox(height: 12),
                InfoCard(
                    icon: Icons.fingerprint,
                    title: 'ID de cuenta',
                    content: authService.cuentaId ?? 'No disponible'),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesion'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => _showLogoutDialog(context, authService),
                ),
              ],
            ),
    );
  }

  Future<void> _showPhotoDialog(
    BuildContext context,
    AuthService authService,
    ProfileService profileService,
    String? currentUrl,
  ) async {
    final controller = TextEditingController(text: currentUrl ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Cambiar foto'),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'URL de imagen',
                    hintText: 'https://...',
                    prefixIcon: Icon(Icons.link),
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) return null;
                    final uri = Uri.tryParse(trimmed);
                    if (uri == null ||
                        uri.host.isEmpty ||
                        !(uri.scheme == 'http' || uri.scheme == 'https')) {
                      return 'Ingresa una URL valida';
                    }
                    return null;
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate() ||
                              authService.cuentaId == null) {
                            return;
                          }
                          setDialogState(() => isSaving = true);
                          final url = controller.text.trim();
                          final success = await profileService
                              .updateProfile(authService.cuentaId!, {
                            'foto_url': url.isEmpty ? null : url,
                          });
                          if (!dialogContext.mounted) return;
                          setDialogState(() => isSaving = false);
                          if (success) {
                            Navigator.pop(dialogContext);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar sesion'),
          content: const Text('Seguro que quieres cerrar sesion?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.of(context).pop();
                await authService.logoutAndClearAllServices(context);
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const Login()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
              child: const Text('Cerrar sesion'),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.fotoUrl, this.onGradient = false});

  final String? fotoUrl;
  final bool onGradient;

  @override
  Widget build(BuildContext context) {
    final url = fotoUrl?.trim();
    return Container(
      padding: EdgeInsets.all(onGradient ? 4 : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onGradient ? Colors.white.withValues(alpha: 0.25) : null,
        border: onGradient
            ? Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2)
            : null,
        boxShadow:
            onGradient ? null : softShadow(opacity: 0.18, blur: 18, y: 8),
      ),
      child: CircleAvatar(
        radius: 46,
        backgroundColor: onGradient ? kBrandBlueAlt : kBrandBlue,
        backgroundImage: url == null || url.isEmpty ? null : NetworkImage(url),
        onBackgroundImageError: url == null || url.isEmpty ? null : (_, __) {},
        child: url == null || url.isEmpty
            ? const Icon(Icons.business, color: Colors.white, size: 40)
            : null,
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.content,
  });

  final IconData icon;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kBrandBlue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: kBrandBlue, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kInkMuted)),
                  const SizedBox(height: 4),
                  Text(content,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: kInk)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
