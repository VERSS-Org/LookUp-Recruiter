import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

class ContactoService with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? message) {
    _errorMessage = message;
  }

  /// Enviar feedback sobre una postulación
  Future<bool> enviarFeedback({
    required String postulacionId,
    required String empresaId,
    required String cuentaId,
    required String tipoFeedback,
    String? mensajeTexto,
    String? motivoRechazo,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final payload = {
        'postulacion_id': postulacionId,
        'empresa_id': empresaId,
        'cuenta_id': cuentaId,
        'tipo_feedback': tipoFeedback,
        if (mensajeTexto != null) 'mensaje_texto': mensajeTexto,
        if (motivoRechazo != null) 'motivo_rechazo': motivoRechazo,
      };

      final response = await _apiService.post('contacto/feedback', payload);

      if (response != null && response['feedback_id'] != null) {
        return true;
      }
      _setError('Error al enviar feedback.');
      return false;
    } catch (e) {
      _setError('Error al enviar feedback: $e');
      debugPrint('Error sending feedback: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Enviar retroalimentación de rechazo
  Future<bool> enviarRechazo({
    required String postulacionId,
    required String empresaId,
    required String cuentaId,
    String? motivoRechazo,
    String? mensaje,
  }) async {
    return enviarFeedback(
      postulacionId: postulacionId,
      empresaId: empresaId,
      cuentaId: cuentaId,
      tipoFeedback: 'rechazo',
      mensajeTexto: mensaje,
      motivoRechazo: motivoRechazo,
    );
  }

  /// Enviar retroalimentación de aprobación/aceptación
  Future<bool> enviarAprobacion({
    required String postulacionId,
    required String empresaId,
    required String cuentaId,
    String? mensaje,
  }) async {
    return enviarFeedback(
      postulacionId: postulacionId,
      empresaId: empresaId,
      cuentaId: cuentaId,
      tipoFeedback: 'aprobacion',
      mensajeTexto: mensaje,
    );
  }

  /// Enviar comentario sobre una postulación
  Future<bool> enviarComentario({
    required String postulacionId,
    required String empresaId,
    required String cuentaId,
    required String mensaje,
  }) async {
    return enviarFeedback(
      postulacionId: postulacionId,
      empresaId: empresaId,
      cuentaId: cuentaId,
      tipoFeedback: 'comentario',
      mensajeTexto: mensaje,
    );
  }
}
