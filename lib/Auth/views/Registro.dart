import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';

class Registro extends StatefulWidget {
  const Registro({super.key});

  @override
  State<Registro> createState() => _RegistroState();
}

class _RegistroState extends State<Registro> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String? errorMessage;
  bool _isLoading = false;
  final String _selectedRole = 'empresa'; // Valor por defecto

  @override
  void dispose() {
    nombreController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    // Validación de campos obligatorios
    if (nombreController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      setState(() =>
          errorMessage = "Por favor completa todos los campos obligatorios.");
      return;
    }

    // Validar email
    if (!emailController.text.contains('@')) {
      setState(() => errorMessage = "Por favor ingresa un correo válido.");
      return;
    }

    // Validar contraseña
    final passwordError = _validateStrongPassword(passwordController.text);
    if (passwordError != null) {
      setState(() => errorMessage = passwordError);
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      setState(() => errorMessage = "Las contraseñas no coinciden.");
      return;
    }

    setState(() {
      _isLoading = true;
      errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      // Usar el nuevo método register() de AuthService
      final success = await authService.register(
        nombreCompleto: nombreController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        rol: _selectedRole,
        carrera: null,
        telefono: null,
        ciudad: null,
      );

      if (!mounted) return;

      if (success != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta creada exitosamente.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      } else {
        setState(() {
          errorMessage = 'No se pudo crear la cuenta. Intenta nuevamente.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString().replaceFirst("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  String? _validateStrongPassword(String password) {
    if (password.length < 8) {
      return "La contrasena debe tener al menos 8 caracteres.";
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return "La contrasena debe incluir una letra mayuscula.";
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return "La contrasena debe incluir una letra minuscula.";
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return "La contrasena debe incluir un numero.";
    }
    if (!password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'))) {
      return "La contrasena debe incluir un caracter especial.";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kInk),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          "Crear Cuenta de Empresa",
          style: TextStyle(
            color: kInk,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),

            // Cabecera
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: kBrandGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: softShadow(opacity: 0.28, blur: 24, y: 12),
                ),
                child: const Icon(
                  Icons.business_center_outlined,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Crea tu cuenta de empresa para empezar a publicar ofertas.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kInkMuted, height: 1.4),
              ),
            ),
            const SizedBox(height: 24),

            // Nombre Completo
            _buildLabel("Nombre completo"),
            _buildTextField(
              controller: nombreController,
              hint: "Ingresa tu nombre completo",
              icon: Icons.person_outline,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Correo
            _buildLabel("Correo electrónico"),
            _buildTextField(
              controller: emailController,
              hint: "Ingresa tu correo",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Contraseña
            _buildLabel("Contraseña"),
            _buildTextField(
              controller: passwordController,
              hint: "Crea una contraseña (mín. 8 caracteres)",
              icon: Icons.lock_outline,
              obscure: true,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Confirmar Contraseña
            _buildLabel("Confirmar contraseña"),
            _buildTextField(
              controller: confirmPasswordController,
              hint: "Repite tu contraseña",
              icon: Icons.lock_outline,
              obscure: true,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Mensaje de Error
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD3D3)),
                  ),
                  child: Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFB42525),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            // Botón Registrar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: kBrandBlue.withValues(alpha: 0.5),
                ),
                onPressed: _isLoading ? null : _registrar,
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text(
                        "Registrar",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 30),

            // Link a Login
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "¿Ya tienes una cuenta? ",
                  style: TextStyle(color: Colors.black87),
                ),
                GestureDetector(
                  onTap: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text(
                    "Inicia sesión",
                    style: TextStyle(
                      color: kBrandBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: kInk,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: kInkMuted),
        hintText: hint,
        hintStyle: const TextStyle(color: kInkMuted),
        filled: true,
        fillColor: enabled ? kFieldFill : const Color(0xFFE9EDF4),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kHairline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kBrandBlue, width: 1.6),
        ),
      ),
    );
  }
}
