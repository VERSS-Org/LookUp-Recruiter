import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

class PuestoService with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<dynamic> _puestosEmpresa = [];
  List<dynamic> get puestosEmpresa => _puestosEmpresa;

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

  /// Limpiar todos los datos de puestos (usado en logout)
  void clearData() {
    _generation++;
    _puestosEmpresa.clear();
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Obtener puestos de una empresa específica
  Future<void> fetchPuestosPorEmpresa(String empresaId) async {
    final generation = _generation;
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.get('puesto/?empresa_id=$empresaId');
      if (generation != _generation) return;
      if (response is List) {
        _puestosEmpresa = response;
      } else {
        _puestosEmpresa = [];
      }
    } catch (e) {
      if (generation != _generation) return;
      _setError('Error al obtener vacantes de la empresa: $e');
      debugPrint('Error fetching puestos por empresa: $e');
    } finally {
      if (generation == _generation) _setLoading(false);
    }
  }

  /// Obtener detalles de un puesto específico
  Future<Map<String, dynamic>?> getPuestoDetails(String puestoId) async {
    final generation = _generation;
    _setError(null);
    try {
      final response = await _apiService.get('puesto/$puestoId');
      if (generation != _generation) return null;
      if (response is Map<String, dynamic>) {
        return response;
      }
      return null;
    } catch (e) {
      if (generation != _generation) return null;
      _setError('Error al obtener detalles de la vacante: $e');
      debugPrint('Error fetching puesto details: $e');
      return null;
    }
  }

  /// Crear un nuevo puesto (para empresas)
  Future<bool> crearPuesto({
    required String empresaId,
    required String titulo,
    required String descripcion,
    required String ubicacion,
    required String tipoContrato,
    double? salarioMin,
    double? salarioMax,
    String? moneda,
    List<Map<String, dynamic>>? requisitos,
  }) async {
    final generation = _generation;
    _setLoading(true);
    _setError(null);
    try {
      final payload = {
        'empresa_id': empresaId,
        'titulo': titulo,
        'descripcion': descripcion,
        'ubicacion': ubicacion,
        'tipo_contrato': tipoContrato,
        if (salarioMin != null) 'salario_min': salarioMin,
        if (salarioMax != null) 'salario_max': salarioMax,
        if (moneda != null) 'moneda': moneda,
        if (requisitos != null) 'requisitos': requisitos,
      };

      final response = await _apiService.post('puesto/', payload);
      if (generation != _generation) return false;
      if (response != null && response['puesto_id'] != null) {
        // Refrescar la lista de puestos de la empresa
        await fetchPuestosPorEmpresa(empresaId);
        return true;
      }
      return false;
    } catch (e) {
      if (generation != _generation) return false;
      _setError('Error al crear la vacante: $e');
      debugPrint('Error creating puesto: $e');
      return false;
    } finally {
      if (generation == _generation) _setLoading(false);
    }
  }

  /// Actualizar un puesto existente
  Future<bool> actualizarPuesto({
    required String puestoId,
    required String empresaId,
    String? titulo,
    String? descripcion,
    String? ubicacion,
    double? salarioMin,
    double? salarioMax,
    String? moneda,
    String? tipoContrato,
    List<Map<String, dynamic>>? requisitos,
  }) async {
    final generation = _generation;
    _setLoading(true);
    _setError(null);
    try {
      final payload = {
        if (titulo != null) 'titulo': titulo,
        if (descripcion != null) 'descripcion': descripcion,
        if (ubicacion != null) 'ubicacion': ubicacion,
        // En edición, null explícito borra el límite salarial en el backend.
        'salario_min': salarioMin,
        'salario_max': salarioMax,
        if (moneda != null) 'moneda': moneda,
        if (tipoContrato != null) 'tipo_contrato': tipoContrato,
        if (requisitos != null) 'requisitos': requisitos,
      };

      final response = await _apiService.put('puesto/$puestoId', payload);
      if (generation != _generation) return false;
      if (response != null && response['puesto_id'] != null) {
        await fetchPuestosPorEmpresa(empresaId);
        return true;
      }
      return false;
    } catch (e) {
      if (generation != _generation) return false;
      _setError('Error al actualizar la vacante: $e');
      debugPrint('Error updating puesto: $e');
      return false;
    } finally {
      if (generation == _generation) _setLoading(false);
    }
  }

  /// Cambiar estado de un puesto (abierto/cerrado)
  Future<bool> cambiarEstadoPuesto(
      String puestoId, String nuevoEstado, String empresaId) async {
    final generation = _generation;
    _setError(null);
    try {
      final response = await _apiService.patch('puesto/$puestoId/estado', {
        'nuevo_estado': nuevoEstado,
      });
      if (generation != _generation) return false;

      if (response != null) {
        await fetchPuestosPorEmpresa(empresaId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (generation != _generation) return false;
      _setError('Error al cambiar estado: $e');
      debugPrint('Error changing puesto status: $e');
      notifyListeners();
      return false;
    }
  }
}
