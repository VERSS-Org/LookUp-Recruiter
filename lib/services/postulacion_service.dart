import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lookup_flutter/services/api_service.dart';

class PostulacionService with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<dynamic> _puestos = [];
  List<dynamic> get puestos => _puestos;

  List<dynamic> _misPostulaciones = [];
  List<dynamic> get misPostulaciones => _misPostulaciones;

  List<dynamic> _postulacionesPuesto = [];
  List<dynamic> get postulacionesPuesto => _postulacionesPuesto;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
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

  /// Limpiar todos los datos de postulaciones (usado en logout)
  void clearData() {
    _puestos.clear();
    _misPostulaciones.clear();
    _postulacionesPuesto.clear();
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
    debugPrint('PostulacionService: Datos limpiados');
  }

  /// Obtener todos los puestos disponibles
  Future<void> fetchPuestos() async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.get('puesto/');
      if (response is List) {
        _puestos = response;
      } else {
        _puestos = [];
      }
    } catch (e) {
      _setError('Error al obtener puestos: $e');
      debugPrint('Error fetching puestos: $e');
      _puestos = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Obtener todas las postulaciones de un candidato
  Future<void> fetchMisPostulaciones(String candidatoId) async {
    _setLoading(true);
    _setError(null);
    try {
      final response =
          await _apiService.get('postulacion/?candidato_id=$candidatoId');
      if (response is List) {
        _misPostulaciones = response;
        debugPrint('Mis postulaciones cargadas: ${_misPostulaciones.length}');
        // Log para verificar estructura de datos
        if (_misPostulaciones.isNotEmpty) {
          debugPrint('Primera postulación: ${_misPostulaciones[0]}');
        }
      } else {
        _misPostulaciones = [];
      }
    } catch (e) {
      _setError('Error al obtener tus postulaciones: $e');
      debugPrint('Error fetching mis postulaciones: $e');
      _misPostulaciones = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Obtener todas las postulaciones para un puesto específico (para empresas)
  Future<void> fetchPostulacionesPorPuesto(String puestoId) async {
    _setLoading(true);
    _setError(null);
    try {
      final response =
          await _apiService.get('postulacion/?puesto_id=$puestoId');
      if (response is List) {
        _postulacionesPuesto = response;
        debugPrint(
            'Postulaciones del puesto cargadas: ${_postulacionesPuesto.length}');
        // Log para verificar estructura de datos
        if (_postulacionesPuesto.isNotEmpty) {
          debugPrint('Primera postulación: ${_postulacionesPuesto[0]}');
        }
      } else {
        _postulacionesPuesto = [];
      }
    } catch (e) {
      _setError('Error al obtener postulaciones: $e');
      debugPrint('Error fetching postulaciones por puesto: $e');
      _postulacionesPuesto = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Crear una nueva postulación (aplicar a un puesto)
  Future<bool> applyForJob(String candidatoId, String puestoId,
      {List<Map<String, dynamic>>? documentos}) async {
    _setLoading(true);
    _setError(null);
    try {
      final payload = {
        'candidato_id': candidatoId,
        'puesto_id': puestoId,
        if (documentos != null) 'documentos_adjuntos': documentos,
      };

      await _apiService.post('postulacion/', payload);

      // Actualizar lista de postulaciones después de aplicar exitosamente
      await fetchMisPostulaciones(candidatoId);
      return true;
    } catch (e) {
      _setError('Error al postular: $e');
      debugPrint('Error applying for job: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Obtener detalles de una postulación específica
  Future<Map<String, dynamic>?> getPostulacionDetails(
      String postulacionId) async {
    _setError(null);
    try {
      final response = await _apiService.get('postulacion/$postulacionId');
      if (response is Map<String, dynamic>) {
        return response;
      }
      return null;
    } catch (e) {
      _setError('Error al obtener detalles: $e');
      debugPrint('Error fetching postulacion details: $e');
      return null;
    }
  }

  /// Actualizar el estado de una postulación
  Future<bool> updateEstadoPostulacion(
      String postulacionId, String nuevoEstado, String puestoId) async {
    _setError(null);
    try {
      await _apiService.patch('postulacion/$postulacionId/estado', {
        'nuevo_estado': nuevoEstado,
      });

      // Refrescar la lista de postulaciones del puesto
      await fetchPostulacionesPorPuesto(puestoId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al actualizar estado: $e');
      debugPrint('Error updating postulacion status: $e');
      notifyListeners();
      return false;
    }
  }
}
