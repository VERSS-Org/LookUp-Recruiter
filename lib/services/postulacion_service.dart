import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lookup_flutter/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestiona las postulaciones recibidas en los puestos de la empresa.
class PostulacionService with ChangeNotifier {
  final ApiService _apiService = ApiService();

  final Map<String, List<dynamic>> _postulacionesPorPuesto = {};
  final Map<String, String> _erroresPorPuesto = {};
  final Set<String> _puestosCargando = {};
  final Map<String, int> _requestVersions = {};

  List<dynamic> postulacionesFor(String puestoId) =>
      _postulacionesPorPuesto[puestoId] ?? const <dynamic>[];

  bool isLoadingFor(String puestoId) => _puestosCargando.contains(puestoId);

  String? errorFor(String puestoId) => _erroresPorPuesto[puestoId];

  List<dynamic> _eventos = [];
  List<dynamic> get eventos => _eventos;
  int _unseenEventos = 0;
  int get unseenEventos => _unseenEventos;
  String? _eventosError;
  String? get eventosError => _eventosError;

  int _generation = 0;

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
    _postulacionesPorPuesto.clear();
    _erroresPorPuesto.clear();
    _puestosCargando.clear();
    _requestVersions.clear();
    _eventos = [];
    _unseenEventos = 0;
    _eventosError = null;
    notifyListeners();
  }

  /// Obtener todas las postulaciones para un puesto especifico
  Future<void> fetchPostulacionesPorPuesto(String puestoId) async {
    final generation = _generation;
    final requestVersion = (_requestVersions[puestoId] ?? 0) + 1;
    _requestVersions[puestoId] = requestVersion;
    _erroresPorPuesto.remove(puestoId);
    _puestosCargando.add(puestoId);
    notifyListeners();
    try {
      final response =
          await _apiService.get('postulacion/?puesto_id=$puestoId');
      if (generation != _generation ||
          _requestVersions[puestoId] != requestVersion) {
        return;
      }
      _postulacionesPorPuesto[puestoId] =
          response is List ? response : <dynamic>[];
    } catch (e) {
      if (generation != _generation ||
          _requestVersions[puestoId] != requestVersion) {
        return;
      }
      // Conserva el último resultado válido de esta misma vacante.
      _erroresPorPuesto[puestoId] = 'Error al obtener postulaciones: $e';
      debugPrint('Error fetching postulaciones por puesto: $e');
    } finally {
      if (generation == _generation &&
          _requestVersions[puestoId] == requestVersion) {
        _puestosCargando.remove(puestoId);
        notifyListeners();
      }
    }
  }

  /// Actualizar el estado de una postulacion y refrescar la lista del puesto
  Future<bool> updateEstadoPostulacion(
      String postulacionId, String nuevoEstado, String puestoId) async {
    final generation = _generation;
    _erroresPorPuesto.remove(puestoId);
    try {
      await _apiService.patch('postulacion/$postulacionId/estado', {
        'nuevo_estado': nuevoEstado,
      });
      if (generation != _generation) return false;

      final cached = _postulacionesPorPuesto[puestoId];
      if (cached != null) {
        for (final postulacion in cached) {
          if (postulacion is Map &&
              postulacion['postulacion_id']?.toString() == postulacionId) {
            postulacion['estado'] = nuevoEstado;
            break;
          }
        }
        notifyListeners();
      }
      await fetchPostulacionesPorPuesto(puestoId);
      return true;
    } on ApiException catch (e) {
      if (generation != _generation) return false;
      _erroresPorPuesto[puestoId] = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      if (generation != _generation) return false;
      _erroresPorPuesto[puestoId] = 'Error al actualizar estado: $e';
      debugPrint('Error updating postulacion status: $e');
      notifyListeners();
      return false;
    }
  }
}
