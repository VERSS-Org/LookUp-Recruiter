import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lookup_flutter/config/portal_links.dart';
import 'package:lookup_flutter/services/api_service.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';
import 'package:lookup_flutter/theme/lookup_widgets.dart';

/// Acceso al portal de empresas.
///
/// La propuesta de valor acompaña al formulario en web y se retira en móvil
/// para priorizar una entrada rápida, legible y sin scroll horizontal.
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
        await authService.logout();
        if (!mounted) return;
        setState(() {
          _errorMessage = context.tr('auth.wrong_app');
          _isLoading = false;
        });
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
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
      backgroundColor: c.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showStory = constraints.maxWidth >= 860;
            final form = _LoginForm(
              formKey: _formKey,
              isLoading: _isLoading,
              hidePassword: _hidePassword,
              errorMessage: _errorMessage,
              showCompactBrand: !showStory,
              onTogglePassword: () =>
                  setState(() => _hidePassword = !_hidePassword),
              onEmailSaved: (value) => _email = value,
              onPasswordSaved: (value) => _password = value,
              onSubmit: _submit,
            );

            if (!showStory) {
              return Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: form,
                  ),
                ),
              );
            }

            final panelWidth = (constraints.maxWidth - 32).clamp(0.0, 1360.0);
            final panelHeight = (constraints.maxHeight - 32).clamp(0.0, 800.0);
            return Center(
              child: SizedBox(
                width: panelWidth,
                height: panelHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 49,
                        child: BrandGradientPanel(
                          borderRadius: BorderRadius.zero,
                          padding: const EdgeInsets.fromLTRB(44, 42, 40, 34),
                          child: const _CompanyStory(),
                        ),
                      ),
                      Expanded(
                        flex: 51,
                        child: ColoredBox(
                          color: c.background,
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 44,
                                vertical: 34,
                              ),
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 370),
                                child: form,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CompanyStory extends StatelessWidget {
  const _CompanyStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const BrandMark(mini: true, size: 24),
            ),
            const SizedBox(width: 10),
            Text(
              context.t('auth.company_brand'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ],
        ),
        const Spacer(flex: 2),
        Text(
          context.t('auth.company.hero'),
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 22),
        for (var index = 1; index <= 3; index++) ...[
          _StoryPoint(
            number: index,
            text: context.t('auth.company.benefit.$index'),
          ),
          if (index != 3) const SizedBox(height: 13),
        ],
        const Spacer(flex: 3),
        Text(
          context.t('auth.company.footer'),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }
}

class _StoryPoint extends StatelessWidget {
  const _StoryPoint({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 23,
          height: 23,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.94),
                height: 1.35,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.isLoading,
    required this.hidePassword,
    required this.errorMessage,
    required this.showCompactBrand,
    required this.onTogglePassword,
    required this.onEmailSaved,
    required this.onPasswordSaved,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final bool hidePassword;
  final String? errorMessage;
  final bool showCompactBrand;
  final VoidCallback onTogglePassword;
  final ValueChanged<String> onEmailSaved;
  final ValueChanged<String> onPasswordSaved;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AutofillGroup(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showCompactBrand) ...[
              const Center(child: BrandMark(size: 52)),
              const SizedBox(height: 28),
            ],
            Text(
              context.t('auth.login.title'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            _FieldLabel(text: context.t('auth.email')),
            const SizedBox(height: 6),
            TextFormField(
              decoration: InputDecoration(
                hintText: context.t('auth.email.example.company'),
                prefixIcon: const Icon(Icons.email_outlined, size: 19),
              ),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email
              ],
              autocorrect: false,
              textInputAction: TextInputAction.next,
              validator: (value) => (value == null || !value.contains('@'))
                  ? context.tr('auth.email.invalid')
                  : null,
              onSaved: (value) => onEmailSaved(value!.trim()),
              enabled: !isLoading,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _FieldLabel(text: context.t('auth.password')),
                const SizedBox(width: 10),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.pushNamed(context, '/recuperar'),
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        context.t('auth.forgot'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline, size: 19),
                suffixIcon: IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(
                    hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 19,
                  ),
                ),
              ),
              obscureText: hidePassword,
              autofillHints: const [AutofillHints.password],
              validator: (value) => (value == null || value.length < 8)
                  ? context.tr('auth.password.short')
                  : null,
              onSaved: (value) => onPasswordSaved(value!),
              enabled: !isLoading,
              onFieldSubmitted: (_) => isLoading ? null : onSubmit(),
            ),
            const SizedBox(height: 16),
            if (errorMessage != null) ErrorBanner(message: errorMessage!),
            ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              child: isLoading
                  ? const SizedBox(
                      height: 19,
                      width: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(context.t('auth.login')),
            ),
            const SizedBox(height: 10),
            InlinePromptLink(
              prompt: context.t('auth.no_account'),
              label: context.t('auth.register.link'),
              onPressed: isLoading
                  ? null
                  : () => Navigator.pushNamed(context, '/registro'),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: Divider(color: c.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    context.t('auth.applicant.prompt'),
                    style: TextStyle(color: c.inkFaint, fontSize: 12),
                  ),
                ),
                Expanded(child: Divider(color: c.border)),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isLoading
                  ? null
                  : () => openApplicantPortal(
                        context,
                        errorMessage: context.tr('auth.applicant.open.error'),
                      ),
              icon: const Icon(Icons.person_outline, size: 18),
              label: Text(context.t('auth.applicant.link')),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

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
