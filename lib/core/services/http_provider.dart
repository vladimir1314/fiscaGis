import 'dart:convert';
import 'package:flutter/foundation.dart'; // Para debugPrint
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class HttpProvider {
  final String _baseUrl = AppConfig.baseUrl;

  // Headers comunes requeridos
  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      'idCliente': AppConfig.idCliente,
    };
  }

  // GET Request
  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('$_baseUrl/$endpoint');
    
    _logRequest('GET', url, _headers);

    try {
      final response = await http.get(url, headers: _headers);
      _logResponse(response);
      return _processResponse(response);
    } catch (e) {
      _logError('GET', url, e);
      rethrow;
    }
  }

  // POST Request
  Future<dynamic> post(String endpoint, {dynamic body}) async {
    final url = Uri.parse('$_baseUrl/$endpoint');
    final jsonBody = body != null ? jsonEncode(body) : null;

    _logRequest('POST', url, _headers, body: jsonBody);

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonBody,
      );
      _logResponse(response);
      return _processResponse(response);
    } catch (e) {
      _logError('POST', url, e);
      rethrow;
    }
  }

  // PUT Request
  Future<dynamic> put(String endpoint, {dynamic body}) async {
    final url = Uri.parse('$_baseUrl/$endpoint');
    final jsonBody = body != null ? jsonEncode(body) : null;

    _logRequest('PUT', url, _headers, body: jsonBody);

    try {
      final response = await http.put(
        url,
        headers: _headers,
        body: jsonBody,
      );
      _logResponse(response);
      return _processResponse(response);
    } catch (e) {
      _logError('PUT', url, e);
      rethrow;
    }
  }

  // DELETE Request
  Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('$_baseUrl/$endpoint');

    _logRequest('DELETE', url, _headers);

    try {
      final response = await http.delete(url, headers: _headers);
      _logResponse(response);
      return _processResponse(response);
    } catch (e) {
      _logError('DELETE', url, e);
      rethrow;
    }
  }

  // Manejo de respuesta
  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return response.body; // Retorna texto plano si no es JSON
      }
    } else {
      // Puedes personalizar la excepción según tu modelo de error
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  // LOGS
  void _logRequest(String method, Uri url, Map<String, String> headers, {String? body}) {
    debugPrint('------------------------------------------------------------------');
    debugPrint('🚀 REQUEST [$method]');
    debugPrint('URL: $url');
    debugPrint('Headers: $headers');
    if (body != null) {
      debugPrint('Body: $body');
    }
    debugPrint('------------------------------------------------------------------');
  }

  void _logResponse(http.Response response) {
    debugPrint('------------------------------------------------------------------');
    debugPrint('📥 RESPONSE [${response.statusCode}]');
    debugPrint('URL: ${response.request?.url}');
    debugPrint('Body: ${response.body}');
    debugPrint('------------------------------------------------------------------');
  }

  void _logError(String method, Uri url, Object error) {
    debugPrint('------------------------------------------------------------------');
    debugPrint('❌ ERROR [$method]');
    debugPrint('URL: $url');
    debugPrint('Details: $error');
    debugPrint('------------------------------------------------------------------');
  }
}