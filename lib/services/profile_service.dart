import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class ProfileService with ChangeNotifier {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profileData;
  bool _isLoading = false;

  Map<String, dynamic>? get profileData => _profileData;
  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Limpiar todos los datos del perfil (usado en logout)
  void clearData() {
    _profileData = null;
    _isLoading = false;
    notifyListeners();
    debugPrint('ProfileService: Datos limpiados');
  }

  /// Obtener información de la cuenta (perfil del usuario)
  Future<Map<String, dynamic>?> fetchProfile(String cuentaId) async {
    _setLoading(true);
    try {
      final response = await _apiService.get('iam/cuenta/$cuentaId');
      if (response is Map<String, dynamic>) {
        _profileData = response;
        notifyListeners();
        return response;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Actualizar información de la cuenta
  Future<bool> updateProfile(
      String cuentaId, Map<String, dynamic> updates) async {
    _setLoading(true);
    try {
      final response = await _apiService.patch('iam/cuenta/$cuentaId', updates);
      if (response is Map<String, dynamic>) {
        _profileData = response;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> uploadProfilePhoto(String cuentaId, XFile file) async {
    _setLoading(true);
    try {
      final response = await _apiService.uploadFile(
          'iam/cuenta/$cuentaId/foto', 'file', file);
      if (response is Map<String, dynamic>) {
        _profileData = response;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Obtener información de la cuenta actual desde AuthService
  Future<Map<String, dynamic>?> getCuentaInfo(String cuentaId) async {
    try {
      final response = await _apiService.get('iam/cuenta/$cuentaId');
      return response;
    } catch (e) {
      debugPrint('Error getting cuenta info: $e');
      return null;
    }
  }
}
