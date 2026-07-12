import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/api_service.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';
import 'package:lookup_flutter/theme/lookup_widgets.dart';

/// Acceso directo para cuentas de empresa mediante un formulario centrado.
class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => LoginState();
}

class LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  bool _hidePassword = true;
  String? _errorMessage;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.login(_email, _password);

      if (!mounted) return;

      if (authService.role == 'empresa') {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        // Esta app es solo para cuentas de empresa.
        await authService.logout();
        if (!mounted) return;
        setState(() {
          _errorMessage = context.tr('auth.wrong_app');
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = context.tr('common.error.connection');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 410),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: BrandMark(size: 64)),
                    const SizedBox(height: 26),
                    _buildForm(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final c = context.colors;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.t('auth.login.title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            context.t('auth.login.subtitle'),
            textAlign: TextAlign.center,
            style: TextStyle(color: c.inkMuted, height: 1.4),
          ),
          const SizedBox(height: 26),
          TextFormField(
            decoration: InputDecoration(
              labelText: context.t('auth.email'),
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            autocorrect: false,
            textInputAction: TextInputAction.next,
            validator: (value) => (value == null || !value.contains('@'))
                ? context.tr('auth.email.invalid')
                : null,
            onSaved: (value) => _email = value!.trim(),
            enabled: !_isLoading,
          ),
          const SizedBox(height: 14),
          TextFormField(
            decoration: InputDecoration(
              labelText: context.t('auth.password'),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
                icon: Icon(
                  _hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            obscureText: _hidePassword,
            autofillHints: const [AutofillHints.password],
            validator: (value) => (value == null || value.length < 8)
                ? context.tr('auth.password.short')
                : null,
            onSaved: (value) => _password = value!,
            enabled: !_isLoading,
            onFieldSubmitted: (_) => _isLoading ? null : _submit(),
          ),
          const SizedBox(height: 20),
          if (_errorMessage != null) ErrorBanner(message: _errorMessage!),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(context.t('auth.login')),
          ),
          const SizedBox(height: 16),
          InlinePromptLink(
            prompt: context.t('auth.no_account'),
            label: context.t('auth.register.link'),
            onPressed: _isLoading
                ? null
                : () => Navigator.pushNamed(context, '/registro'),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _isLoading
                ? null
                : () => Navigator.pushNamed(context, '/recuperar'),
            child: Text(
              context.t('auth.forgot'),
              style: TextStyle(color: c.inkMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
