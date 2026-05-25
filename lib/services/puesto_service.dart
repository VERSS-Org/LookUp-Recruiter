import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

class PuestoService with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<dynamic> _puestos = [];
  List<dynamic> get puestos => _puestos;

  List<dynamic> _puestosEmpresa = [];
  List<dynamic> get puestosEmpresa => _puestosEmpresa;

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

  /// Limpiar todos los datos de puestos (usado en logout)
  void clearData() {
    _puestos.clear();
    _puestosEmpresa.clear();
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
    debugPrint('PuestoService: Datos limpiados');
  }

  /// Obtener todos los puestos (para postulantes)
  Future<void> fetchAllPuestos({String? estado}) async {
    _setLoading(true);
    _setError(null);
    try {
      String endpoint = 'puesto/';
      if (estado != null) {
        endpoint += '?estado=$estado';
      }
      final response = await _apiService.get(endpoint);
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

  /// Obtener puestos de una empresa específica
  Future<void> fetchPuestosPorEmpresa(String empresaId) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.get('puesto/?empresa_id=$empresaId');
      if (response is List) {
        _puestosEmpresa = response;
      } else {
        _puestosEmpresa = [];
      }
    } catch (e) {
      _setError('Error al obtener puestos de la empresa: $e');
      debugPrint('Error fetching puestos por empresa: $e');
      _puestosEmpresa = [];
    } finally {
      _setLoading(false);
    }
  }
   /// Contar el número de puestos activos de una empresa
  Future<int> getNumeroOfertasActivas(String empresaId) async {
    _setError(null);
    try {
      final response = await _apiService.get('puesto/?empresa_id=$empresaId&estado=abierto');
      if (response is List) {
        return response.length;
      }
      return 0;
    } catch (e) {
      _setError('Error al contar las ofertas activas: $e');
      debugPrint('Error counting active puestos: $e');
      return 0;
    }
  }

  /// Contar el número de puestos cerrados de una empresa
  Future<int> getNumeroOfertasCerradas(String empresaId) async {
    _setError(null);
    try {
      final response = await _apiService.get('puesto/?empresa_id=$empresaId&estado=cerrado');
      if (response is List) {
        return response.length;
      }
      return 0;
    } catch (e) {
      _setError('Error al contar las ofertas cerradas: $e');
      debugPrint('Error counting closed puestos: $e');
      return 0;
    }
  }

  /// Obtener detalles de un puesto específico
  Future<Map<String, dynamic>?> getPuestoDetails(String puestoId) async {
    _setError(null);
    try {
      final response = await _apiService.get('puesto/$puestoId');
      if (response is Map<String, dynamic>) {
        return response;
      }
      return null;
    } catch (e) {
      _setError('Error al obtener detalles del puesto: $e');
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
      if (response != null && response['puesto_id'] != null) {
        // Refrescar la lista de puestos de la empresa
        await fetchPuestosPorEmpresa(empresaId);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Error al crear puesto: $e');
      debugPrint('Error creating puesto: $e');
      return false;
    } finally {
      _setLoading(false);
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
    _setLoading(true);
    _setError(null);
    try {
      final payload = {
        if (titulo != null) 'titulo': titulo,
        if (descripcion != null) 'descripcion': descripcion,
        if (ubicacion != null) 'ubicacion': ubicacion,
        if (salarioMin != null) 'salario_min': salarioMin,
        if (salarioMax != null) 'salario_max': salarioMax,
        if (moneda != null) 'moneda': moneda,
        if (tipoContrato != null) 'tipo_contrato': tipoContrato,
        if (requisitos != null) 'requisitos': requisitos,
      };

      final response = await _apiService.put('puesto/$puestoId', payload);
      if (response != null && response['puesto_id'] != null) {
        await fetchPuestosPorEmpresa(empresaId);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Error al actualizar puesto: $e');
      debugPrint('Error updating puesto: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cambiar estado de un puesto (abierto/cerrado)
  Future<bool> cambiarEstadoPuesto(String puestoId, String nuevoEstado, String empresaId) async {
    _setError(null);
    try {
      final response = await _apiService.patch('puesto/$puestoId/estado', {
        'nuevo_estado': nuevoEstado,
      });

      if (response != null) {
        await fetchPuestosPorEmpresa(empresaId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Error al cambiar estado: $e');
      debugPrint('Error changing puesto status: $e');
      notifyListeners();
      return false;
    }
  }
}
