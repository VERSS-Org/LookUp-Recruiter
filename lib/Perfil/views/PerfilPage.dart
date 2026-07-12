import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/services/profile_service.dart';
import 'package:lookup_flutter/services/theme_controller.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';
import 'package:lookup_flutter/theme/lookup_widgets.dart';
import 'package:lookup_flutter/theme/photo_cropper.dart';

/// Perfil de la cuenta de empresa: datos, descripción, logo, apariencia,
/// idioma y seguridad.
class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key, this.showBack = false});

  final bool showBack;

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    final cuentaId = context.read<AuthService>().cuentaId;
    if (cuentaId == null) return;
    await context.read<ProfileService>().fetchProfile(cuentaId);
  }

  Map<String, dynamic> _perfilDe(Map<String, dynamic> profile) {
    final raw = profile['perfil'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final profileService = Provider.of<ProfileService>(context);
    final themeController = context.watch<ThemeController>();
    final localeController = context.watch<LocaleController>();
    final c = context.colors;
    final profile = profileService.profileData ?? const <String, dynamic>{};
    final perfil = _perfilDe(profile);
    final nombre = profile['nombre_completo']?.toString() ?? 'Empresa';
    final descripcion = perfil['descripcion']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBack,
        leading: widget.showBack
            ? IconButton(
                tooltip: context.t('common.back'),
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(context.t('profile.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditDialog(context, authService, profile),
            tooltip: context.t('profile.edit'),
          ),
        ],
      ),
      body: profileService.isLoading && profile.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : profileService.errorMessage != null && profile.isEmpty
              ? PageContainer(
                  maxWidth: 760,
                  child: ListView(
                    padding: const EdgeInsets.all(22),
                    children: [
                      ErrorBanner(
                        message: context.t('profile.load.error'),
                        actionLabel: context.t('common.retry'),
                        onAction: _loadProfile,
                      ),
                    ],
                  ),
                )
              : PageContainer(
                  maxWidth: 760,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      MediaQuery.sizeOf(context).width < 480 ? 16 : 22,
                      22,
                      MediaQuery.sizeOf(context).width < 480 ? 16 : 22,
                      32,
                    ),
                    children: [
                      if (profileService.errorMessage != null) ...[
                        ErrorBanner(
                          message: context.t('profile.load.error'),
                          actionLabel: context.t('common.retry'),
                          onAction: _loadProfile,
                        ),
                        const SizedBox(height: 12),
                      ],
                      ProfileBanner(
                        avatar: InitialsAvatar(
                          name: nombre,
                          size: 88,
                          imageUrl: profile['foto_url']?.toString(),
                          fallbackIcon: Icons.business_outlined,
                        ),
                        title: nombre,
                        subtitle: [
                          if ((profile['ciudad']?.toString() ?? '').isNotEmpty)
                            profile['ciudad'].toString(),
                        ].join(' · '),
                        caption: profile['email']?.toString() ?? '',
                        action: OutlinedButton.icon(
                          icon:
                              const Icon(Icons.photo_camera_outlined, size: 17),
                          label: Text(context.t('profile.change_logo')),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: () => _showPhotoDialog(context),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SectionLabel(
                        title: context.t('profile.about'),
                        actionLabel: context.t('profile.edit'),
                        onAction: () =>
                            _editarDescripcion(context, perfil, descripcion),
                      ),
                      Text(
                        descripcion.isEmpty
                            ? context.t('profile.about.hint')
                            : descripcion,
                        style: TextStyle(
                          color: descripcion.isEmpty ? c.inkFaint : c.ink,
                          height: 1.5,
                          fontSize: 14.5,
                          fontStyle:
                              descripcion.isEmpty ? FontStyle.italic : null,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SectionLabel(title: context.t('profile.details')),
                      InfoRow(
                        icon: Icons.email_outlined,
                        label: context.t('auth.email'),
                        value: profile['email']?.toString() ?? '—',
                      ),
                      InfoRow(
                        icon: Icons.phone_outlined,
                        label: context.t('profile.phone'),
                        value: (profile['telefono']?.toString() ?? '').isEmpty
                            ? context.t('common.not_specified')
                            : profile['telefono'].toString(),
                      ),
                      InfoRow(
                        icon: Icons.location_on_outlined,
                        label: context.t('profile.city'),
                        value: (profile['ciudad']?.toString() ?? '').isEmpty
                            ? context.t('common.not_specified_f')
                            : profile['ciudad'].toString(),
                      ),
                      const SizedBox(height: 22),
                      SectionLabel(title: context.t('settings.title')),
                      Text(
                        context.t('settings.theme'),
                        style: TextStyle(fontSize: 13.5, color: c.inkMuted),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<ThemeMode>(
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text(context.t('settings.theme.light')),
                              icon: const Icon(Icons.light_mode_outlined,
                                  size: 17),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text(context.t('settings.theme.dark')),
                              icon: const Icon(Icons.dark_mode_outlined,
                                  size: 17),
                            ),
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text(context.t('settings.theme.system')),
                              icon: const Icon(
                                Icons.brightness_auto_outlined,
                                size: 17,
                              ),
                            ),
                          ],
                          selected: {themeController.mode},
                          onSelectionChanged: (selection) =>
                              themeController.setMode(selection.first),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.t('settings.language'),
                        style: TextStyle(fontSize: 13.5, color: c.inkMuted),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'es', label: Text('Español')),
                          ButtonSegment(value: 'en', label: Text('English')),
                        ],
                        selected: {localeController.language},
                        onSelectionChanged: (selection) =>
                            localeController.setLanguage(selection.first),
                      ),
                      const SizedBox(height: 24),
                      SectionLabel(title: context.t('settings.security')),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.lock_outline),
                        label: Text(context.t('settings.change_password')),
                        onPressed: () =>
                            _showChangePasswordDialog(context, authService),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: Text(context.t('nav.logout')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.danger,
                          side: BorderSide(
                              color: c.danger.withValues(alpha: 0.4)),
                        ),
                        onPressed: () =>
                            _showLogoutDialog(context, authService),
                      ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _editarDescripcion(
    BuildContext context,
    Map<String, dynamic> perfil,
    String actual,
  ) async {
    final profileService = Provider.of<ProfileService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final controller = TextEditingController(text: actual);
    final resultado = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('profile.about')),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 6,
            maxLength: 600,
            decoration: InputDecoration(
              hintText: context.tr('profile.about.hint'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(context.tr('common.save')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (resultado != null && context.mounted && authService.cuentaId != null) {
      final success =
          await profileService.updateProfile(authService.cuentaId!, {
        'perfil': {...perfil, 'descripcion': resultado},
      });
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('profile.update.error')),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    AuthService authService,
    Map<String, dynamic> profile,
  ) async {
    final profileService = Provider.of<ProfileService>(context, listen: false);
    final nameController =
        TextEditingController(text: profile['nombre_completo']?.toString());
    final phoneController =
        TextEditingController(text: profile['telefono']?.toString());
    final cityController =
        TextEditingController(text: profile['ciudad']?.toString());
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;
        String? errorMessage;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(context.tr('profile.edit')),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: context.tr('auth.company_name'),
                            prefixIcon: const Icon(Icons.business_outlined),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? context.tr('form.required')
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: context.tr('profile.phone'),
                            prefixIcon: const Icon(Icons.phone_outlined),
                          ),
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            errorMessage!,
                            style: TextStyle(
                              color: context.colors.danger,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: cityController,
                          decoration: InputDecoration(
                            labelText: context.tr('profile.city'),
                            prefixIcon: const Icon(Icons.location_on_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.pop(dialogContext),
                  child: Text(context.tr('common.cancel')),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          final cuentaId = authService.cuentaId;
                          if (cuentaId == null) return;
                          setDialogState(() => isSaving = true);
                          final success = await profileService.updateProfile(
                            cuentaId,
                            {
                              'nombre_completo': nameController.text.trim(),
                              'telefono': phoneController.text.trim(),
                              'ciudad': cityController.text.trim(),
                            },
                          );
                          if (!dialogContext.mounted) return;
                          setDialogState(() => isSaving = false);
                          if (success) Navigator.pop(dialogContext);
                          if (!success) {
                            setDialogState(() {
                              errorMessage = context.tr('profile.update.error');
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.tr('common.save')),
                ),
              ],
            );
          },
        );
      },
    );
    nameController.dispose();
    phoneController.dispose();
    cityController.dispose();
  }

  Future<void> _showPhotoDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => const _LogoDialog(),
    );
  }

  Future<void> _showChangePasswordDialog(
    BuildContext context,
    AuthService authService,
  ) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final rootMessenger = ScaffoldMessenger.of(context);
    final successMessage = context.tr('settings.password.updated.login');
    final actualController = TextEditingController();
    final nuevaController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    String? validarFuerte(String? password) {
      if (password == null || password.length < 8) {
        return context.tr('auth.password.hint');
      }
      final ok = password.contains(RegExp(r'[A-Z]')) &&
          password.contains(RegExp(r'[a-z]')) &&
          password.contains(RegExp(r'[0-9]')) &&
          password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'));
      return ok ? null : context.tr('auth.password.hint');
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;
        String? errorMessage;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(context.tr('settings.change_password')),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: actualController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: context.tr('settings.password.current'),
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? context.tr('form.required')
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: nuevaController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: context.tr('settings.password.new'),
                            prefixIcon: const Icon(Icons.lock_reset_outlined),
                            helperText: context.tr('auth.password.hint'),
                            helperMaxLines: 2,
                          ),
                          validator: validarFuerte,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: confirmController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: context.tr('settings.password.confirm'),
                            prefixIcon: const Icon(Icons.lock_reset_outlined),
                          ),
                          validator: (value) => value != nuevaController.text
                              ? context.tr('auth.password.mismatch')
                              : null,
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            errorMessage!,
                            style: TextStyle(
                              color: context.colors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.pop(dialogContext),
                  child: Text(context.tr('common.cancel')),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() {
                            isSaving = true;
                            errorMessage = null;
                          });
                          final result = await authService.changePassword(
                            actualController.text,
                            nuevaController.text,
                          );
                          if (!dialogContext.mounted) return;
                          if (result != null && result['exito'] == true) {
                            Navigator.pop(dialogContext);
                            await authService.logout();
                            if (rootNavigator.mounted) {
                              rootNavigator.pushNamedAndRemoveUntil(
                                '/login',
                                (route) => false,
                              );
                              rootMessenger.showSnackBar(
                                SnackBar(content: Text(successMessage)),
                              );
                            }
                          } else {
                            setDialogState(() {
                              isSaving = false;
                              errorMessage = context.tr(
                                'settings.password.error',
                              );
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.tr('common.update')),
                ),
              ],
            );
          },
        );
      },
    );
    actualController.dispose();
    nuevaController.dispose();
    confirmController.dispose();
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(dialogContext.tr('nav.logout')),
          content: Text('${dialogContext.tr('nav.logout')}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(dialogContext.tr('common.cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: dialogContext.colors.danger,
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await authService.logout();
                if (rootNavigator.mounted) {
                  rootNavigator.pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              },
              child: Text(dialogContext.tr('nav.logout')),
            ),
          ],
        );
      },
    );
  }
}

/// Diálogo del logo con recorte y zoom (acercar/alejar).
class _LogoDialog extends StatefulWidget {
  const _LogoDialog();

  @override
  State<_LogoDialog> createState() => _LogoDialogState();
}

class _LogoDialogState extends State<_LogoDialog> {
  final ImagePicker _picker = ImagePicker();
  final GlobalKey<PhotoCropperState> _cropperKey = GlobalKey();
  Uint8List? _bytes;
  String? _error;
  bool _isSaving = false;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 88,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    if (bytes.length > 3 * 1024 * 1024) {
      setState(() => _error = context.tr('photo.too_big'));
      return;
    }
    setState(() {
      _bytes = bytes;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_bytes == null) {
      setState(() => _error = context.tr('photo.pick_first'));
      return;
    }
    final auth = context.read<AuthService>();
    final profileService = context.read<ProfileService>();
    if (auth.cuentaId == null) return;
    setState(() => _isSaving = true);
    try {
      final png = await _cropperKey.currentState?.exportPng();
      if (!mounted) return;
      if (png == null) {
        setState(() => _error = context.tr('photo.error'));
        return;
      }
      final file = XFile.fromData(
        png,
        name: 'logo.png',
        mimeType: 'image/png',
      );
      final success =
          await profileService.uploadProfilePhoto(auth.cuentaId!, file);
      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
      } else {
        setState(() => _error = context.tr('photo.error'));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AlertDialog(
      title: Text(context.t('photo.title')),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_bytes == null)
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: c.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.business, color: c.inkFaint, size: 72),
              )
            else ...[
              PhotoCropper(key: _cropperKey, imageBytes: _bytes!),
              const SizedBox(height: 4),
              Text(
                context.t('photo.adjust'),
                textAlign: TextAlign.center,
                style: TextStyle(color: c.inkFaint, fontSize: 12),
              ),
            ],
            const SizedBox(height: 14),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: Text(
                _bytes == null
                    ? context.t('photo.pick')
                    : context.t('photo.change'),
              ),
              onPressed: _isSaving ? null : _pickImage,
            ),
            const SizedBox(height: 6),
            Text(
              context.t('photo.formats'),
              textAlign: TextAlign.center,
              style: TextStyle(color: c.inkFaint, fontSize: 12),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.danger, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(context.t('common.cancel')),
        ),
        FilledButton(
          onPressed: _isSaving || _bytes == null ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.t('photo.upload')),
        ),
      ],
    );
  }
}
