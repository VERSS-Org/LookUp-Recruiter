import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService with ChangeNotifier {
  final ApiService _apiService = ApiService();
  String? _token;
  String? _refreshToken;
  String? _role;
  String? _cuentaId;
  bool _isLoading = false;

  String? get token => _token;
  String? get refreshToken => _refreshToken;
  String? get role => _role;
  String? get profileId => _cuentaId; // Alias para compatibilidad
  String? get cuentaId => _cuentaId;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  AuthService() {
    _apiService.setRefreshTokenHandler(refreshAccessToken);
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token') || !prefs.containsKey('cuentaId')) {
      return false;
    }
    _token = prefs.getString('token');
    _refreshToken = prefs.getString('refreshToken');
    _role = prefs.getString('role');
    _cuentaId = prefs.getString('cuentaId');
    _apiService.setToken(_token);

    final loaded = await _loadCurrentAccount();
    if (loaded) {
      notifyListeners();
      return true;
    }

    final refreshed = await refreshAccessToken();
    if (refreshed && await _loadCurrentAccount()) {
      notifyListeners();
      return true;
    }

    await logout();
    return false;
  }

  Future<void> _saveCredentials(
      String token, String? refreshToken, String role, String cuentaId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    if (refreshToken != null) {
      await prefs.setString('refreshToken', refreshToken);
    }
    await prefs.setString('role', role);
    await prefs.setString('cuentaId', cuentaId);

    _token = token;
    _refreshToken = refreshToken;
    _role = role;
    _cuentaId = cuentaId;
    _apiService.setToken(token);
    debugPrint("Credenciales guardadas. Rol: $_role, CuentaID: $_cuentaId");
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _token = null;
    _refreshToken = null;
    _role = null;
    _cuentaId = null;
    _apiService.setToken(null);
    debugPrint("Usuario deslogueado y credenciales eliminadas.");
    notifyListeners();
  }

  /// Método para limpiar todos los servicios durante el logout
  Future<void> logoutAndClearAllServices(BuildContext context) async {
    try {
      // Limpiar AuthService primero
      await logout();

      // Notificar a todos los listeners que se ha hecho logout
      // Los otros servicios pueden escuchar cambios en AuthService y limpiarse automáticamente
      debugPrint("Logout completado - AuthService limpio");
    } catch (e) {
      debugPrint("Error durante logout: $e");
      // Asegurar que al menos AuthService se limpie
      await logout();
    }
  }

  Future<Map<String, dynamic>?> register({
    required String nombreCompleto,
    required String email,
    required String password,
    required String rol,
    String? carrera,
    String? telefono,
    String? ciudad,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final registerResponse = await _apiService.post('iam/registrar', {
        'nombre_completo': nombreCompleto,
        'email': email,
        'password': password,
        'rol': rol,
        'carrera': carrera,
        'telefono': telefono,
        'ciudad': ciudad,
      });

      if (registerResponse != null && registerResponse['cuenta_id'] != null) {
        // Loguear automáticamente después del registro exitoso
        return await login(email, password);
      } else {
        throw Exception('Failed to create account.');
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final loginResponse = await _apiService.post('iam/login', {
        'email': email,
        'password': password,
      });

      if (loginResponse != null &&
          loginResponse['access_token'] != null &&
          loginResponse['cuenta_id'] != null) {
        final token = loginResponse['access_token'];
        final refreshToken = loginResponse.containsKey('refresh_token')
            ? loginResponse['refresh_token']
            : null;
        final userRole = loginResponse['rol'] ?? 'postulante';
        final cuentaId = loginResponse['cuenta_id'];

        await _saveCredentials(token, refreshToken, userRole, cuentaId);

        return loginResponse;
      } else {
        throw Exception('Invalid login response.');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) {
      return false;
    }

    try {
      final response = await _apiService.post(
        'iam/refresh-token',
        {'refresh_token': _refreshToken},
        retryOnUnauthorized: false,
      );

      if (response != null && response['access_token'] != null) {
        final newToken = response['access_token'];
        _token = newToken;
        _apiService.setToken(newToken);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', newToken);

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      return false;
    }
  }

  Future<bool> _loadCurrentAccount() async {
    try {
      final response = await _apiService.get('iam/me');
      if (response is! Map<String, dynamic>) return false;

      _cuentaId = response['cuenta_id']?.toString() ?? _cuentaId;
      _role = response['rol']?.toString() ?? _role;

      final prefs = await SharedPreferences.getInstance();
      if (_cuentaId != null) await prefs.setString('cuentaId', _cuentaId!);
      if (_role != null) await prefs.setString('role', _role!);
      return true;
    } catch (e) {
      debugPrint('Stored session is not valid: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> changePassword(
      String passwordActual, String passwordNuevo) async {
    if (_cuentaId == null) {
      return null;
    }

    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post('iam/cambiar-password', {
        'password_actual': passwordActual,
        'password_nuevo': passwordNuevo,
      });

      return response;
    } catch (e) {
      debugPrint('Change password error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getCuentaInfo() async {
    if (_cuentaId == null) {
      return null;
    }

    try {
      final response = await _apiService.get('iam/cuenta/$_cuentaId');
      return response;
    } catch (e) {
      debugPrint('Get cuenta info error: $e');
      return null;
    }
  }
}
