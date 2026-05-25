import 'package:flutter/material.dart';

class CrearPostulacion extends StatefulWidget {
  const CrearPostulacion({super.key});

  @override
  State<CrearPostulacion> createState() => _CrearPostulacionState();
}

class _CrearPostulacionState extends State<CrearPostulacion> {
  final TextEditingController tituloController = TextEditingController();
  final TextEditingController empresaController = TextEditingController(text: "Innovatech Solutions");
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController direccionController = TextEditingController(); 
  final TextEditingController requisitosController = TextEditingController();

  String? _selectedCiudad;
  final List<String> _ciudades = [
    'Lima', 'Arequipa', 'Trujillo', 'Chiclayo', 'Piura', 'Cusco', 'Huancayo', 
    'Iquitos', 'Tacna', 'Chimbote', 'Juliaca', 'Ica', 'Pucallpa', 'Sullana', 
    'Ayacucho', 'Cajamarca', 'Tarma', 'Huanuco', 'Huaraz'
  ];

  String tipoContrato = "Tiempo completo";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Crear Nueva Oferta",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Título del Puesto"),
            _buildTextField(
              controller: tituloController,
              hint: "Ej: Diseñador UI/UX Senior",
              icon: Icons.work_outline,
            ),
            const SizedBox(height: 16),

            _buildLabel("Empresa"),
            _buildReadOnlyBox(icon: Icons.apartment_outlined, text: empresaController.text),
            const SizedBox(height: 16),

            _buildLabel("Descripción del Puesto"),
            _buildTextField(
              controller: descripcionController,
              hint: "Describe las responsabilidades y el día a día del puesto...",
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            _buildLabel("Dirección Exacta (Distrito/Avenida)"),
            _buildTextField(
              controller: direccionController,
              hint: "Ej: Miraflores, Av. Larco 123",
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 16),
            
            _buildLabel("Ciudad"),
            _buildCityDropdown(),
            const SizedBox(height: 16),

            _buildLabel("Tipo de Contrato"),
            _buildDropdown(),
            const SizedBox(height: 16),

            _buildLabel("Requisitos"),
            _buildTextField(
              controller: requisitosController,
              hint: "Ej: 5 años de experiencia con React, conocimiento de Figma...",
              maxLines: 2,
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  _crearPostulacion();
                },
                child: const Text(
                  "Publicar Oferta",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _crearPostulacion() {
    if (direccionController.text.isEmpty || _selectedCiudad == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa la dirección y selecciona una ciudad.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final String ubicacionFinal = "${direccionController.text}, $_selectedCiudad";

    // Aquí iría la lógica para enviar al backend
    // Por ahora, solo mostramos un mensaje de éxito
    print("Ubicación a guardar: $ubicacionFinal");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Oferta publicada correctamente'),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey[700]) : null,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 1.3),
        ),
      ),
    );
  }

  Widget _buildReadOnlyBox({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700]),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildCityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCiudad,
          isExpanded: true,
          hint: const Text("Selecciona una ciudad"),
          items: _ciudades.map((String ciudad) {
            return DropdownMenuItem<String>(
              value: ciudad,
              child: Text(ciudad),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedCiudad = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: tipoContrato,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: "Tiempo completo", child: Text("Tiempo completo")),
            DropdownMenuItem(value: "Medio tiempo", child: Text("Medio tiempo")),
            DropdownMenuItem(value: "Prácticas", child: Text("Prácticas")),
            DropdownMenuItem(value: "Freelance", child: Text("Freelance")),
          ],
          onChanged: (value) => setState(() => tipoContrato = value!),
        ),
      ),
    );
  }
}
