import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/services/auth_service.dart';

class Registro extends StatefulWidget {
  const Registro({super.key});

  @override
  State<Registro> createState() => _RegistroState();
}

class _RegistroState extends State<Registro> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

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
      setState(() => errorMessage = "Por favor completa todos los campos obligatorios.");
      return;
    }

    // Validar email
    if (!emailController.text.contains('@')) {
      setState(() => errorMessage = "Por favor ingresa un correo válido.");
      return;
    }

    // Validar contraseña
    if (passwordController.text.length < 8) {
      setState(() => errorMessage = "La contraseña debe tener al menos 8 caracteres.");
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
        // Registro exitoso, mostrar mensaje y volver a login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cuenta creada exitosamente! Ahora inicia sesión.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Volver a la pantalla de login
        Navigator.of(context).pop();
      } else {
        setState(() {
          errorMessage = 'Error en el registro. El correo podría ya estar en uso.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          "Crear Cuenta de Empresa",
          style: TextStyle(
            color: Colors.black87,
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
            const SizedBox(height: 10),

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
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red[700],
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
                  backgroundColor: const Color(0xFF0A6375),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: const Color(0xFF0A6375).withOpacity(0.5),
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
                      color: Color(0xFF0A6375),
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
        color: Colors.black87,
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
        prefixIcon: Icon(icon, color: const Color(0xFF0A6375)),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0A6375), width: 1.3),
        ),
      ),
    );
  }
}
