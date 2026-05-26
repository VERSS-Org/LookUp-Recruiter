import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';

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
  String? _errorMessage;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.login(_email, _password);

      if (!mounted) return;

      if (success != null) {
        // Login exitoso - redirigir según rol
        final rol = authService.role;

        if (rol == 'empresa') {
          // Empresas van a Home para gestionar puestos
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/home', (route) => false);
        } else {
          // Si no es empresa, no se permite el login
          setState(() {
            _errorMessage = 'Solo se permite el acceso a cuentas de empresa.';
            _isLoading = false;
          });
          authService.logout();
        }
      } else {
        setState(() {
          _errorMessage = 'Correo o contraseña incorrectos.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final formWidth = viewportWidth < 700
        ? (viewportWidth - 128).clamp(280, 320).toDouble()
        : 440.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE7EEFB), kSurface],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
              child: SizedBox(
                width: formWidth,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        margin: const EdgeInsets.only(bottom: 22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: softShadow(opacity: 0.12, blur: 26, y: 12),
                        ),
                        child: Image.asset(
                          'assets/images/logo_lookup.png',
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: softShadow(opacity: 0.10, blur: 30, y: 16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Bienvenido a LookUp',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              color: kInk,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Inicia sesión para continuar',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: kInkMuted),
                          ),
                          const SizedBox(height: 26),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Correo Electrónico',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) =>
                                      (value == null || !value.contains('@'))
                                          ? 'Correo inválido'
                                          : null,
                                  onSaved: (value) => _email = value!,
                                  enabled: !_isLoading,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Contraseña',
                                    prefixIcon: Icon(Icons.lock_outline),
                                  ),
                                  obscureText: true,
                                  validator: (value) =>
                                      (value == null || value.length < 6)
                                          ? 'La contraseña es muy corta'
                                          : null,
                                  onSaved: (value) => _password = value!,
                                  enabled: !_isLoading,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFFFD3D3),
                                  ),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFB42525),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: _submit,
                                  child: const Text('Iniciar Sesión'),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pushNamed(context, '/registro');
                            },
                      child: const Text(
                        '¿No tienes cuenta de empresa? Regístrate',
                        style: TextStyle(
                          color: kBrandBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.pushNamed(context, '/recuperar');
                              },
                        child: const Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(color: kInkMuted, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
