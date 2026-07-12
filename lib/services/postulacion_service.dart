import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lookup_flutter/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestiona las postulaciones recibidas en los puestos de la empresa.
class PostulacionService with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<dynamic> _postulacionesPuesto = [];
  List<dynamic> get postulacionesPuesto => _postulacionesPuesto;

  List<dynamic> _eventos = [];
  List<dynamic> get eventos => _eventos;
  int _unseenEventos = 0;
  int get unseenEventos => _unseenEventos;
  String? _eventosError;
  String? get eventosError => _eventosError;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  int _generation = 0;

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? message) {
    _errorMessage = message;
  }

  static const _lastSeenKey = 'lastSeenEventosEmpresa';

  /// Novedades de los últimos 7 días (nuevas postulaciones recibidas).
  Future<void> fetchEventos({bool notify = true}) async {
    final generation = _generation;
    _eventosError = null;
    try {
      final response = await _apiService.get('postulacion/eventos');
      if (generation != _generation) return;
      _eventos = response is List ? response : <dynamic>[];
    } catch (e) {
      if (generation != _generation) return;
      _eventosError = 'No se pudieron cargar las notificaciones.';
      debugPrint('Error fetching eventos: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    if (generation != _generation) return;
    final lastSeen = prefs.getString(_lastSeenKey) ?? '';
    _unseenEventos = _eventos
        .where((e) =>
            e is Map && (e['fecha']?.toString() ?? '').compareTo(lastSeen) > 0)
        .length;
    if (notify) notifyListeners();
  }

  Future<void> markEventosSeen() async {
    final generation = _generation;
    if (_eventos.isEmpty && _unseenEventos == 0) return;
    final prefs = await SharedPreferences.getInstance();
    var latest = '';
    for (final e in _eventos) {
      final fecha = e is Map ? (e['fecha']?.toString() ?? '') : '';
      if (fecha.compareTo(latest) > 0) latest = fecha;
    }
    if (generation != _generation) return;
    if (latest.isNotEmpty) await prefs.setString(_lastSeenKey, latest);
    if (generation != _generation) return;
    if (_unseenEventos != 0) {
      _unseenEventos = 0;
      notifyListeners();
    }
  }

  /// Limpiar todos los datos de postulaciones (usado en logout)
  void clearData() {
    _generation++;
    _postulacionesPuesto.clear();
    _eventos = [];
    _unseenEventos = 0;
    _eventosError = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Obtener todas las postulaciones para un puesto especifico
  Future<void> fetchPostulacionesPorPuesto(String puestoId) async {
    final generation = _generation;
    _setLoading(true);
    _setError(null);
    try {
      final response =
          await _apiService.get('postulacion/?puesto_id=$puestoId');
      if (generation != _generation) return;
      _postulacionesPuesto = response is List ? response : [];
    } catch (e) {
      if (generation != _generation) return;
      _setError('Error al obtener postulaciones: $e');
      debugPrint('Error fetching postulaciones por puesto: $e');
    } finally {
      if (generation == _generation) _setLoading(false);
    }
  }

  /// Actualizar el estado de una postulacion y refrescar la lista del puesto
  Future<bool> updateEstadoPostulacion(
      String postulacionId, String nuevoEstado, String puestoId) async {
    final generation = _generation;
    _setError(null);
    try {
      await _apiService.patch('postulacion/$postulacionId/estado', {
        'nuevo_estado': nuevoEstado,
      });
      if (generation != _generation) return false;

      await fetchPostulacionesPorPuesto(puestoId);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      if (generation != _generation) return false;
      _setError(e.message);
      notifyListeners();
      return false;
    } catch (e) {
      if (generation != _generation) return false;
      _setError('Error al actualizar estado: $e');
      debugPrint('Error updating postulacion status: $e');
      notifyListeners();
      return false;
    }
  }
}
