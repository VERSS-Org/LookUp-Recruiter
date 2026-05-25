import 'package:flutter/material.dart';
import 'package:lookup_flutter/Postulacion/views/DetallePostulacion.dart';

class EditarPostulacion extends StatefulWidget {
  final Map<String, dynamic> oferta;

  const EditarPostulacion({super.key, required this.oferta});

  @override
  State<EditarPostulacion> createState() => _EditarPostulacionState();
}

class _EditarPostulacionState extends State<EditarPostulacion> {
  late TextEditingController tituloController;
  late TextEditingController empresaController;
  late TextEditingController descripcionController;
  late TextEditingController ubicacionController;
  late TextEditingController requisitosController;

  String tipoContrato = "Tiempo completo";

  @override
  void initState() {
    super.initState();
    tituloController = TextEditingController(text: widget.oferta["titulo"]);
    empresaController = TextEditingController(text: "Innovatech Solutions Inc.");
    descripcionController = TextEditingController(
      text:
      "Buscamos un Desarrollador o Diseñador apasionado por crear productos digitales excepcionales. Serás responsable de diseñar, probar e implementar soluciones innovadoras en un entorno ágil.",
    );
    ubicacionController = TextEditingController(text: "Santiago, Chile (Híbrido)");
    requisitosController = TextEditingController(
      text:
      "Experiencia comprobable en desarrollo de software o diseño UI/UX. Dominio de herramientas modernas y trabajo colaborativo.",
    );
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Editar Oferta",
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
            _buildTextField(controller: tituloController),

            const SizedBox(height: 16),
            _buildLabel("Nombre de la Empresa"),
            _buildTextField(controller: empresaController),

            const SizedBox(height: 16),
            _buildLabel("Descripción del Puesto"),
            _buildTextField(controller: descripcionController, maxLines: 4),

            const SizedBox(height: 16),
            _buildLabel("Ubicación"),
            _buildTextField(controller: ubicacionController),

            const SizedBox(height: 16),
            _buildLabel("Tipo de Contrato"),
            _buildDropdown(),

            const SizedBox(height: 16),
            _buildLabel("Requisitos"),
            _buildTextField(controller: requisitosController, maxLines: 3),

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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cambios guardados (demo)')),
                  );

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => DetallePostulacion(oferta: widget.oferta)),
                  );
                },
                child: const Text(
                  "Guardar Cambios",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
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
            DropdownMenuItem(value: "Freelance", child: Text("Freelance")),
            DropdownMenuItem(value: "Prácticas", child: Text("Prácticas")),
          ],
          onChanged: (value) => setState(() => tipoContrato = value!),
        ),
      ),
    );
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
}
