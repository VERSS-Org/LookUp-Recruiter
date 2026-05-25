import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _defaultBaseUrl = String.fromEnvironment(
    'LOOKUP_API_BASE_URL',
    defaultValue: 'https://backend-ufl2-git-main-glitter22s-projects.vercel.app/api/',
  );
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal();

  final Uri _baseUri = Uri.parse(_normalizeBaseUrl(_defaultBaseUrl));
  String? _token;

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim().replaceFirst(RegExp(r'/+$'), '');
    final apiBase = trimmed.endsWith('/api') ? trimmed : '$trimmed/api';
    return '$apiBase/';
  }

  void setToken(String? token) {
    _token = token;
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

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final url = _baseUri.resolve(endpoint);
    final headers = await _getHeaders();
    
    var response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(data),
    );

    // Handle 307/308 redirects for POST requests
    if (response.statusCode == 307 || response.statusCode == 308) {
      final location = response.headers['location'];
      if (location != null) {
        debugPrint('Redirect detected to: $location. Retrying POST request.');
        final redirectUrl = Uri.parse(location);

        response = await http.post(
          redirectUrl,
          headers: headers,
          body: jsonEncode(data),
        );
      }
    }

    return _processResponse(response);
  }

  Future<dynamic> get(String endpoint) async {
    final url = _baseUri.resolve(endpoint);
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    return _processResponse(response);
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    final url = _baseUri.resolve(endpoint);
    final headers = await _getHeaders();
    final response = await http.patch(
      url,
      headers: headers,
      body: jsonEncode(data),
    );
    return _processResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final url = _baseUri.resolve(endpoint);
    final headers = await _getHeaders();
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(data),
    );
    return _processResponse(response);
  }

  dynamic _processResponse(http.Response response) {
    // Enhanced debugging
    debugPrint('API Response => Status: ${response.statusCode}, URL: ${response.request?.url}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {}; // Successful but no content
      }
      try {
        return jsonDecode(response.body);
      } catch (e) {
        // If body is not a valid JSON, it might be an unhandled success case
        return response.body;
      }
    } else {
      // Throw an exception with the status code to be caught by the service
      debugPrint('API Error Body: ${response.body}');
      throw Exception('Request failed with status: ${response.statusCode}');
    }
  }
}
