import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/api_service.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';
import 'package:lookup_flutter/theme/lookup_widgets.dart';

/// Acceso para cuentas de empresa. En escritorio muestra un panel de marca a
/// la izquierda y el formulario a la derecha; en móvil, una sola columna.
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
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 900;
            final form = Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: desktop ? 48 : 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 410),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!desktop) ...[
                        const Center(child: BrandMark(size: 64)),
                        const SizedBox(height: 26),
                      ],
                      _buildForm(context),
                    ],
                  ),
                ),
              ),
            );

            if (!desktop) return form;
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    color: c.surfaceAlt,
                    padding: const EdgeInsets.all(48),
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const BrandMark(size: 92),
                          const SizedBox(height: 36),
                          Text(
                            context.t('auth.company.access'),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            context.t('app.tagline'),
                            style: TextStyle(
                              color: c.inkMuted,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: ColoredBox(color: c.surface, child: form),
                ),
              ],
            );
          },
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
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            context.t('auth.login.subtitle'),
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
            validator: (value) => (value == null || value.length < 6)
                ? context.tr('auth.password.hint')
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
          const SizedBox(height: 10),
          TextButton(
            onPressed: _isLoading
                ? null
                : () => Navigator.pushNamed(context, '/registro'),
            child: Text(context.t('auth.register.cta')),
          ),
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
