import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class ProfileService with ChangeNotifier {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profileData;
  bool _isLoading = false;
  String? _errorMessage;
  int _generation = 0;

  Map<String, dynamic>? get profileData => _profileData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Limpiar todos los datos del perfil (usado en logout)
  void clearData() {
    _generation++;
    _profileData = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Obtener información de la cuenta (perfil del usuario)
  Future<Map<String, dynamic>?> fetchProfile(String cuentaId) async {
    final generation = _generation;
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _apiService.get('iam/cuenta/$cuentaId');
      if (generation != _generation) return null;
      if (response is Map<String, dynamic>) {
        _profileData = response;
        notifyListeners();
        return response;
      }
      return null;
    } catch (e) {
      if (generation != _generation) return null;
      _errorMessage = 'No se pudo cargar el perfil de empresa.';
      debugPrint('Error fetching profile: $e');
      return null;
    } finally {
      if (generation == _generation) _setLoading(false);
    }
  }

  /// Actualizar información de la cuenta
  Future<bool> updateProfile(
      String cuentaId, Map<String, dynamic> updates) async {
    final generation = _generation;
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _apiService.patch('iam/cuenta/$cuentaId', updates);
      if (generation != _generation) return false;
      if (response is Map<String, dynamic>) {
        _profileData = response;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (generation != _generation) return false;
      _errorMessage = 'No se pudo actualizar el perfil de empresa.';
      debugPrint('Error updating profile: $e');
      return false;
    } finally {
      if (generation == _generation) _setLoading(false);
    }
  }

  Future<bool> uploadProfilePhoto(String cuentaId, XFile file) async {
    final generation = _generation;
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _apiService.uploadFile(
          'iam/cuenta/$cuentaId/foto', 'file', file);
      if (generation != _generation) return false;
      if (response is Map<String, dynamic>) {
        _profileData = response;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (generation != _generation) return false;
      _errorMessage = 'No se pudo actualizar el logo de la empresa.';
      debugPrint('Error uploading profile photo: $e');
      return false;
    } finally {
      if (generation == _generation) _setLoading(false);
    }
  }
}
