import 'package:flutter/material.dart';
import 'package:lookup_flutter/services/api_service.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';
import 'package:lookup_flutter/theme/lookup_widgets.dart';
import 'package:lookup_flutter/Auth/views/auth_frame.dart';

/// Recuperación de contraseña en dos pasos: correo -> código + nueva clave.
class RecuperarContrasenia extends StatefulWidget {
  const RecuperarContrasenia({super.key});

  @override
  State<RecuperarContrasenia> createState() => _RecuperarContraseniaState();
}

class _RecuperarContraseniaState extends State<RecuperarContrasenia> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _codeSent = false;
  bool _isLoading = false;
  bool _hidePassword = true;
  bool _hideConfirm = true;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validarFuerte(String? password) {
    if (password == null || password.length < 8) {
      return context.tr('auth.password.hint');
    }
    final ok = password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'));
    return ok ? null : context.tr('auth.password.hint');
  }

  Future<void> _requestCode() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _api.post(
        'iam/recuperar-password',
        {'email': email},
        retryOnUnauthorized: false,
      );
      if (!mounted) return;
      final codigoDev = response is Map ? response['codigo_dev'] : null;
      setState(() {
        _codeSent = true;
        _info = response is Map ? response['mensaje']?.toString() : null;
        // Sin servicio de correo, en desarrollo el backend devuelve el
        // código para poder completar el flujo localmente.
        if (codigoDev != null) {
          _codeController.text = codigoDev.toString();
        }
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.tr('common.error.connection'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReset() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _api.post(
          'iam/restablecer-password',
          {
            'email': _emailController.text.trim(),
            'codigo': _codeController.text.trim(),
            'password_nuevo': _passwordController.text,
          },
          retryOnUnauthorized: false);
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('reset.success'))),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.tr('common.error.connection'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AuthPageFrame(
      title: context.t('reset.title'),
      contentMaxWidth: 420,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: c.brand.withValues(alpha: c.chipAlpha),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.lock_reset_rounded, size: 27, color: c.brand),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _codeSent
                  ? context.t('reset.step2.title')
                  : context.t('reset.question'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              _codeSent
                  ? context.t('reset.step2.hint')
                  : context.t('reset.subtitle'),
              style: TextStyle(color: c.inkMuted, height: 1.45),
            ),
            const SizedBox(height: 22),
            _ResetLabel(text: context.t('auth.email')),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              enabled: !_codeSent && !_isLoading,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              decoration: InputDecoration(
                hintText: context.t('auth.email.example.company'),
                prefixIcon: const Icon(Icons.email_outlined, size: 19),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                    ? null
                    : context.tr('auth.email.invalid');
              },
            ),
            if (_codeSent) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() {
                            _codeSent = false;
                            _codeController.clear();
                            _passwordController.clear();
                            _confirmController.clear();
                            _error = null;
                            _info = null;
                          }),
                  child: Text(context.t('reset.change_email')),
                ),
              ),
              const SizedBox(height: 14),
              _ResetLabel(text: context.t('reset.code')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _codeController,
                enabled: !_isLoading,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: context.t('reset.code.hint'),
                  prefixIcon: const Icon(Icons.pin_outlined, size: 19),
                ),
                validator: (value) => value == null || value.trim().length != 6
                    ? context.tr('reset.code.hint')
                    : null,
              ),
              const SizedBox(height: 14),
              _ResetLabel(text: context.t('reset.new_password')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passwordController,
                enabled: !_isLoading,
                obscureText: _hidePassword,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline, size: 19),
                  helperText: context.t('auth.password.hint'),
                  helperMaxLines: 2,
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _hidePassword = !_hidePassword,
                    ),
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: _validarFuerte,
              ),
              const SizedBox(height: 14),
              _ResetLabel(text: context.t('reset.confirm_password')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _confirmController,
                enabled: !_isLoading,
                obscureText: _hideConfirm,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline, size: 19),
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _hideConfirm = !_hideConfirm,
                    ),
                    icon: Icon(
                      _hideConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) => value != _passwordController.text
                    ? context.tr('auth.password.mismatch')
                    : null,
              ),
            ],
            const SizedBox(height: 18),
            if (_error != null) ErrorBanner(message: _error!),
            if (_info != null && _error == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _info!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.inkMuted, fontSize: 13),
                ),
              ),
            ElevatedButton(
              onPressed:
                  _isLoading ? null : (_codeSent ? _submitReset : _requestCode),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _codeSent
                          ? context.t('reset.submit')
                          : context.t('reset.send_code'),
                    ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false),
              child: Text(context.t('reset.back_login')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResetLabel extends StatelessWidget {
  const _ResetLabel({required this.text});

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
