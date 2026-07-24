import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.isConnectionError = false});

  final String message;
  final int? statusCode;
  final bool isConnectionError;

  bool get isUnauthorized =>
      statusCode == 401 || message.toLowerCase().contains('token');

  @override
  String toString() => message;
}

class ApiService {
  /// URL base del backend. Sobreescribible en compilacion con:
  /// flutter run --dart-define=LOOKUP_API_BASE_URL=https://mi-backend/api/
  /// (en Android Emulator usa http://10.0.2.2:8000; en dispositivo fisico,
  /// la IP LAN de la PC que corre el backend).
  static const String _defaultBaseUrl = String.fromEnvironment(
    'LOOKUP_API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/',
  );
  static final ApiService _instance = ApiService._internal();
  static const Duration _requestTimeout = Duration(seconds: 8);

  factory ApiService() => _instance;

  ApiService._internal();

  final Uri _baseUri = Uri.parse(_normalizeBaseUrl(_defaultBaseUrl));
  String? _token;
  Future<bool> Function()? _refreshTokenHandler;

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim().replaceFirst(RegExp(r'/+$'), '');
    final apiBase = trimmed.endsWith('/api') ? trimmed : '$trimmed/api';
    return '$apiBase/';
  }

  void setToken(String? token) {
    _token = token;
  }

  void setRefreshTokenHandler(Future<bool> Function()? handler) {
    _refreshTokenHandler = handler;
  }

  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool retryOnUnauthorized = true,
  }) async {
    final url = _baseUri.resolve(endpoint);
    final headers = await _getHeaders();

    var response = await _send(
      () => http.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      ),
    );

    // Handle 307/308 redirects for POST requests
    if (response.statusCode == 307 || response.statusCode == 308) {
      final location = response.headers['location'];
      if (location != null) {
        if (kDebugMode) {
          debugPrint('La API redirigió una solicitud POST; reintentando.');
        }
        final redirectUrl = url.resolve(location);

        response = await _send(
          () => http.post(
            redirectUrl,
            headers: headers,
            body: jsonEncode(data),
          ),
        );
      }
    }

    if (!retryOnUnauthorized) return _processResponse(response);

    return _processResponse(await _retryIfUnauthorized(response, () async {
      var retry = await _send(
        () async => http.post(
          url,
          headers: await _getHeaders(),
          body: jsonEncode(data),
        ),
      );

      if (retry.statusCode == 307 || retry.statusCode == 308) {
        final retryLocation = retry.headers['location'];
        if (retryLocation != null) {
          retry = await _send(
            () async => http.post(
              url.resolve(retryLocation),
              headers: await _getHeaders(),
              body: jsonEncode(data),
            ),
          );
        }
      }
      return retry;
    }));
  }

  Future<dynamic> get(String endpoint) async {
    final url = _baseUri.resolve(endpoint);
    final headers = await _getHeaders();
    final response = await _send(() => http.get(url, headers: headers));
    return _processResponse(await _retryIfUnauthorized(
      response,
      () async => _send(
        () async => http.get(url, headers: await _getHeaders()),
      ),
    ));
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    final url = _baseUri.resolve(endpoint);
    final headers = await _getHeaders();
    final response = await _send(
      () => http.patch(
        url,
        headers: headers,
        body: jsonEncode(data),
      ),
    );
    return _processResponse(await _retryIfUnauthorized(
      response,
      () async => _send(
        () async => http.patch(
          url,
          headers: await _getHeaders(),
          body: jsonEncode(data),
        ),
      ),
    ));
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final url = _baseUri.resolve(endpoint);
    final headers = await _getHeaders();
    final response = await _send(
      () => http.put(
        url,
        headers: headers,
        body: jsonEncode(data),
      ),
    );
    return _processResponse(await _retryIfUnauthorized(
      response,
      () async => _send(
        () async => http.put(
          url,
          headers: await _getHeaders(),
          body: jsonEncode(data),
        ),
      ),
    ));
  }

  Future<dynamic> uploadFile(
      String endpoint, String fieldName, XFile file) async {
    Future<http.Response> send() async {
      final request = http.MultipartRequest('POST', _baseUri.resolve(endpoint));
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          await file.readAsBytes(),
          filename: file.name,
        ),
      );
      return _send(
        () async => http.Response.fromStream(await request.send()),
      );
    }

    final response = await send();
    return _processResponse(await _retryIfUnauthorized(response, send));
  }

  Future<http.Response> _retryIfUnauthorized(
    http.Response response,
    Future<http.Response> Function() retry,
  ) async {
    if (response.statusCode != 401 || _refreshTokenHandler == null) {
      return response;
    }

    final refreshed = await _refreshTokenHandler!();
    if (!refreshed) return response;
    return retry();
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(_requestTimeout);
    } on TimeoutException {
      throw ApiException(
        'El servidor tardó demasiado en responder. Inténtalo nuevamente.',
        isConnectionError: true,
      );
    } on http.ClientException {
      throw ApiException(
        'No se pudo conectar con el servidor. Verifica que esté disponible.',
        isConnectionError: true,
      );
    }
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {}; // Successful but no content
      }
      try {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } catch (e) {
        // If body is not a valid JSON, it might be an unhandled success case
        return response.body;
      }
    } else {
      if (kDebugMode) {
        // No registra URL ni cuerpo: pueden contener identificadores o PII.
        debugPrint('La API respondió con estado ${response.statusCode}.');
      }
      dynamic decoded;
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        decoded = null;
      }

      final detail = decoded is Map ? decoded['detail'] : null;
      throw ApiException(
        detail?.toString() ??
            'Request failed with status: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
  }
}
