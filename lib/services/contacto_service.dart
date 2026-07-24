import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

/// Conversaciones de la empresa con sus postulantes, por postulación.
class ContactoService with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isBandejaLoading = false;
  String? _bandejaError;
  List<dynamic> _bandeja = [];
  final Map<String, List<dynamic>> _contactosPorPostulacion = {};
  final Map<String, String> _erroresPorPostulacion = {};
  final Set<String> _contactosCargando = {};
  int _generation = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isBandejaLoading => _isBandejaLoading;
  String? get bandejaError => _bandejaError;
  List<dynamic> get bandeja => _bandeja;

  /// Mensajes sin leer en toda la bandeja (para el badge).
  int get unreadMessages => _bandeja.fold(
      0,
      (total, hilo) =>
          total +
          ((hilo is Map ? hilo['no_leidos'] as num? : null)?.toInt() ?? 0));

  List<dynamic> contactosFor(String postulacionId) =>
      _contactosPorPostulacion[postulacionId] ?? const <dynamic>[];
  String? contactosErrorFor(String postulacionId) =>
      _erroresPorPostulacion[postulacionId];
  bool isLoadingContactos(String postulacionId) =>
      _contactosCargando.contains(postulacionId);

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? message) {
    _errorMessage = message;
  }

  void clearData() {
    _generation++;
    _bandeja = [];
    _contactosPorPostulacion.clear();
    _erroresPorPostulacion.clear();
    _contactosCargando.clear();
    _isLoading = false;
    _errorMessage = null;
    _isBandejaLoading = false;
    _bandejaError = null;
    notifyListeners();
  }

  Future<void> fetchBandeja({bool notify = true}) async {
    final generation = _generation;
    if (notify && _isBandejaLoading) return;
    _bandejaError = null;
    if (notify && !_isBandejaLoading) {
      _isBandejaLoading = true;
      notifyListeners();
    }
    try {
      final response = await _apiService.get('contacto/bandeja');
      if (generation != _generation) return;
      _bandeja = response is List ? response : <dynamic>[];
    } catch (e) {
      if (generation != _generation) return;
      _bandejaError = 'No se pudieron cargar las conversaciones.';
      debugPrint('Error fetching bandeja: $e');
    } finally {
      if (generation == _generation && notify) _isBandejaLoading = false;
    }
    if (generation == _generation && notify) notifyListeners();
  }

  Future<List<dynamic>> fetchContactos(String postulacionId) async {
    if (_contactosCargando.contains(postulacionId)) {
      return contactosFor(postulacionId);
    }
    final generation = _generation;
    _erroresPorPostulacion.remove(postulacionId);
    _contactosCargando.add(postulacionId);
    notifyListeners();
    try {
      final response =
          await _apiService.get('contacto/?postulacion_id=$postulacionId');
      if (generation != _generation) return const <dynamic>[];
      final contactos = response is List ? response : <dynamic>[];
      _contactosPorPostulacion[postulacionId] = contactos;
      _erroresPorPostulacion.remove(postulacionId);
      return contactos;
    } catch (e) {
      if (generation != _generation) return const <dynamic>[];
      _erroresPorPostulacion[postulacionId] =
          'Error al cargar la conversación: $e';
      debugPrint('Error fetching contacts: $e');
      // Mantiene el último hilo válido para que un fallo transitorio no haga
      // desaparecer mensajes que el usuario ya había visto.
      return contactosFor(postulacionId);
    } finally {
      if (generation == _generation) {
        _contactosCargando.remove(postulacionId);
        notifyListeners();
      }
    }
  }

  /// Envía un mensaje simple del hilo (chat fluido).
  Future<void> enviarMensaje(String postulacionId, String texto) async {
    final generation = _generation;
    await _apiService.post('contacto/mensaje', {
      'postulacion_id': postulacionId,
      'mensaje_texto': texto,
    });
    if (generation != _generation) return;
    await fetchContactos(postulacionId);
    await fetchBandeja(notify: false);
    notifyListeners();
  }

  Future<void> marcarLeidos(String postulacionId) async {
    final generation = _generation;
    try {
      await _apiService.post('contacto/marcar-leidos', {
        'postulacion_id': postulacionId,
      });
      if (generation != _generation) return;
      for (final hilo in _bandeja) {
        if (hilo is Map &&
            hilo['postulacion_id']?.toString() == postulacionId) {
          hilo['no_leidos'] = 0;
        }
      }
      notifyListeners();
    } catch (e) {
      if (generation != _generation) return;
      debugPrint('Error marking read: $e');
    }
  }

  /// Enviar feedback formal (comentario, aprobación u rechazo).
  /// La aprobación/rechazo actualiza el estado de la postulación en el backend.
  Future<bool> enviarFeedback({
    required String postulacionId,
    required String empresaId,
    required String cuentaId,
    required String tipoFeedback,
    String? mensajeTexto,
    String? motivoRechazo,
  }) async {
    final generation = _generation;
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
      if (generation != _generation) return false;

      if (response != null && response['feedback_id'] != null) {
        await fetchContactos(postulacionId);
        await fetchBandeja(notify: false);
        notifyListeners();
        return true;
      }
      _setError('Error al enviar feedback.');
      return false;
    } on ApiException catch (e) {
      if (generation != _generation) return false;
      _setError(e.message);
      return false;
    } catch (e) {
      if (generation != _generation) return false;
      _setError('Error al enviar feedback: $e');
      debugPrint('Error sending feedback: $e');
      return false;
    } finally {
      if (generation == _generation) _setLoading(false);
    }
  }
}
