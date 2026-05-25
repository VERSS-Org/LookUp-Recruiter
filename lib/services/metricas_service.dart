import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

class MetricasService with ChangeNotifier {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _metricasResumen;
  bool _isLoading = false;

  Map<String, dynamic>? get metricasResumen => _metricasResumen;
  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void clearData() {
    _metricasResumen = null;
    _isLoading = false;
    notifyListeners();
    debugPrint('MetricasService: Datos limpiados');
  }

  Future<void> fetchMetricasResumen(String cuentaId) async {
    _setLoading(true);
    try {
      final response = await _apiService.get('metricas/resumen/$cuentaId');
      if (response is Map<String, dynamic>) {
        _metricasResumen = response;
        notifyListeners(); // Notify listeners after data is fetched
      }
    } catch (e) {
      debugPrint('Error fetching metrics resumen: $e');
      _metricasResumen = null;
    } finally {
      _setLoading(false);
    }
  }
}
