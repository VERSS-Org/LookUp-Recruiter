import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/api_service.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';
import 'package:lookup_flutter/theme/lookup_widgets.dart';
import 'package:lookup_flutter/Auth/views/auth_frame.dart';

/// Registro de una nueva cuenta de empresa.
class Registro extends StatefulWidget {
  const Registro({super.key});

  @override
  State<Registro> createState() => _RegistroState();
}

class _RegistroState extends State<Registro> {
  final _formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? errorMessage;
  bool _isLoading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    nombreController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final success = await authService.register(
        nombreCompleto: nombreController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        rol: 'empresa',
        carrera: null,
        telefono: null,
        ciudad: null,
      );

      if (!mounted) return;

      if (success != null) {
        if (authService.role != 'empresa') {
          await authService.logout();
          if (!mounted) return;
          setState(() {
            errorMessage = context.tr('auth.wrong_app');
            _isLoading = false;
          });
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('auth.register.success')),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        setState(() {
          errorMessage = context.tr('auth.register.error');
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = context.tr('common.error.connection');
        _isLoading = false;
      });
    }
  }

  bool _isStrongPassword(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'));
  }

  String? _validateStrongPassword(String? password) {
    return password != null && _isStrongPassword(password)
        ? null
        : context.tr('auth.password.hint');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AuthPageFrame(
      title: context.t('auth.register.title'),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BrandMark(size: 46),
                  const SizedBox(width: 8),
                  Text(
                    context.t('nav.company'),
                    style: TextStyle(
                      color: c.inkMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _FormLabel(text: context.t('auth.company_name')),
              const SizedBox(height: 6),
              TextFormField(
                controller: nombreController,
                autofillHints: const [AutofillHints.organizationName],
                enabled: !_isLoading,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.business_outlined, size: 19),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? context.tr('auth.company_name.required')
                    : null,
              ),
              const SizedBox(height: 14),
              _FormLabel(text: context.t('auth.email')),
              const SizedBox(height: 6),
              TextFormField(
                controller: emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined, size: 19),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                      ? null
                      : context.tr('auth.email.invalid');
                },
              ),
              const SizedBox(height: 14),
              _FormLabel(text: context.t('auth.password')),
              const SizedBox(height: 6),
              TextFormField(
                key: const ValueKey('company-register-password-field'),
                controller: passwordController,
                enabled: !_isLoading,
                obscureText: _hidePassword,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline, size: 19),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _hidePassword = !_hidePassword),
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 19,
                    ),
                  ),
                ),
                validator: _validateStrongPassword,
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) => _isLoading ? null : _registrar(),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final strong = _isStrongPassword(passwordController.text);
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        key: const ValueKey('password-strength-icon'),
                        strong
                            ? Icons.check_circle
                            : Icons.info_outline_rounded,
                        size: 15,
                        color: strong ? c.success : c.inkFaint,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          context.t('auth.password.hint'),
                          style: TextStyle(
                            color: strong ? c.success : c.inkMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              if (errorMessage != null) ErrorBanner(message: errorMessage!),
              ElevatedButton(
                onPressed: _isLoading ? null : _registrar,
                child: _isLoading
                    ? const SizedBox(
                        height: 19,
                        width: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(context.t('auth.register')),
              ),
              const SizedBox(height: 10),
              InlinePromptLink(
                prompt: context.t('auth.has_account'),
                label: context.t('auth.login.link'),
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                          (route) => false,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.text});

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
