import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService with ChangeNotifier {
  AuthService({VoidCallback? onSessionCleared})
      : _onSessionCleared = onSessionCleared {
    _apiService.setRefreshTokenHandler(refreshAccessToken);
  }

  final ApiService _apiService = ApiService();
  final VoidCallback? _onSessionCleared;
  String? _token;
  String? _refreshToken;
  String? _role;
  String? _cuentaId;
  bool _isLoading = false;
  int _sessionGeneration = 0;
  Future<bool>? _refreshFuture;
  Future<void>? _logoutFuture;

  String? get token => _token;
  String? get refreshToken => _refreshToken;
  String? get role => _role;
  String? get cuentaId => _cuentaId;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final refreshToken = prefs.getString('refreshToken');
    final cuentaId = prefs.getString('cuentaId');
    if (token == null ||
        token.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty ||
        cuentaId == null ||
        cuentaId.isEmpty) {
      await logout();
      return false;
    }
    _sessionGeneration++;
    _token = token;
    _refreshToken = refreshToken;
    _role = prefs.getString('role');
    _cuentaId = cuentaId;
    _apiService.setToken(_token);

    final loaded = await _loadCurrentAccount();
    if (loaded) {
      notifyListeners();
      return true;
    }

    await logout();
    return false;
  }

  Future<void> _saveCredentials(
      String token, String refreshToken, String role, String cuentaId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('refreshToken', refreshToken);
    await prefs.setString('role', role);
    await prefs.setString('cuentaId', cuentaId);

    _sessionGeneration++;
    _token = token;
    _refreshToken = refreshToken;
    _role = role;
    _cuentaId = cuentaId;
    _apiService.setToken(token);
    notifyListeners();
  }

  Future<void> logout() {
    final pending = _logoutFuture;
    if (pending != null) return pending;

    final logoutGeneration = ++_sessionGeneration;
    _token = null;
    _refreshToken = null;
    _role = null;
    _cuentaId = null;
    _apiService.setToken(null);
    _onSessionCleared?.call();
    notifyListeners();

    final future = _removeStoredCredentials(logoutGeneration);
    _logoutFuture = future;
    future.then(
      (_) {
        if (identical(_logoutFuture, future)) _logoutFuture = null;
      },
      onError: (_) {
        if (identical(_logoutFuture, future)) _logoutFuture = null;
      },
    );
    return future;
  }

  Future<void> _removeStoredCredentials(int logoutGeneration) async {
    final prefs = await SharedPreferences.getInstance();
    // Mantiene preferencias del dispositivo (idioma y tema), pero elimina
    // todo dato que pueda vincular la siguiente sesión con la cuenta anterior.
    await Future.wait([
      prefs.remove('token'),
      prefs.remove('refreshToken'),
      prefs.remove('role'),
      prefs.remove('cuentaId'),
      prefs.remove('lastSeenEventosEmpresa'),
    ]);
    // Una segunda limpieza captura respuestas que terminaron mientras se
    // eliminaban las credenciales. No toca una sesión iniciada posteriormente.
    if (_sessionGeneration == logoutGeneration) {
      _onSessionCleared?.call();
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
        throw ApiException(
          'El servidor no confirmó la creación de la cuenta.',
        );
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inicia sesion. Lanza [ApiException] con el detalle del backend si falla.
  Future<Map<String, dynamic>> login(String email, String password) async {
    final pendingLogout = _logoutFuture;
    if (pendingLogout != null) await pendingLogout;
    _isLoading = true;
    notifyListeners();
    final loginGeneration = _sessionGeneration;
    try {
      final loginResponse = await _apiService.post('iam/login', {
        'email': email.trim(),
        'password': password,
      });

      if (loginResponse is! Map) {
        throw ApiException('Respuesta de login incompleta.');
      }

      final token = loginResponse['access_token']?.toString() ?? '';
      final refreshToken = loginResponse['refresh_token']?.toString() ?? '';
      final userRole = loginResponse['rol']?.toString() ?? '';
      final cuentaId = loginResponse['cuenta_id']?.toString() ?? '';
      if (token.isEmpty ||
          refreshToken.isEmpty ||
          userRole.isEmpty ||
          cuentaId.isEmpty) {
        throw ApiException('Respuesta de login incompleta.');
      }
      if (loginGeneration != _sessionGeneration) {
        throw ApiException('El inicio de sesión fue cancelado.');
      }

      await _saveCredentials(token, refreshToken, userRole, cuentaId);

      return Map<String, dynamic>.from(loginResponse);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> refreshAccessToken() async {
    final pending = _refreshFuture;
    if (pending != null) return pending;

    final future = _refreshAccessTokenOnce();
    _refreshFuture = future;
    future.then(
      (_) {
        if (identical(_refreshFuture, future)) _refreshFuture = null;
      },
      onError: (_) {
        if (identical(_refreshFuture, future)) _refreshFuture = null;
      },
    );
    return future;
  }

  Future<bool> _refreshAccessTokenOnce() async {
    final refreshToken = _refreshToken;
    final refreshGeneration = _sessionGeneration;
    if (refreshToken == null || refreshToken.isEmpty) {
      await logout();
      return false;
    }

    try {
      final response = await _apiService.post(
        'iam/refresh-token',
        {'refresh_token': refreshToken},
        retryOnUnauthorized: false,
      );

      if (refreshGeneration != _sessionGeneration ||
          refreshToken != _refreshToken) {
        return false;
      }

      final newToken =
          response is Map ? response['access_token']?.toString() ?? '' : '';
      if (newToken.isNotEmpty) {
        _token = newToken;
        _apiService.setToken(newToken);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', newToken);

        notifyListeners();
        return true;
      }
      await logout();
      return false;
    } on ApiException catch (e) {
      debugPrint('Token refresh error: $e');
      if (e.isConnectionError || (e.statusCode ?? 0) >= 500) {
        rethrow;
      }
      if (refreshGeneration == _sessionGeneration &&
          {400, 401, 403, 404}.contains(e.statusCode)) {
        await logout();
      }
      return false;
    } catch (e) {
      // Un fallo de red transitorio no borra una sesión potencialmente válida.
      debugPrint('Token refresh unavailable: $e');
      rethrow;
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
    } on ApiException catch (e) {
      if (e.isConnectionError || (e.statusCode ?? 0) >= 500) {
        rethrow;
      }
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

  @override
  void dispose() {
    _apiService.setRefreshTokenHandler(null);
    super.dispose();
  }
}
