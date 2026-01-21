import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class HttpProvider {
  final String _baseUrl = AppConfig.baseUrl;

  // Headers comunes requeridos
  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      'x-id-cliente': AppConfig.idCliente,
      //'Authorization': 'Bearer eyJhbGciOiJkaXIiLCJlbmMiOiJBMjU2R0NNIn0..nifhMxj4eavMx3KN.q3R0filDT2CkmyX8r2ShVtJGKfU4gFDBWzIjeR9FSEsvRF9APuHBDjDXZ-G7DfgY1ckaR61fE0SG8xUgODN7DGSN-l6oUuucXmr0T1FTXTWN6-1qeg0aSwE4qI5-rDgQlq4wuX7t1IUynYgWCTu-U4NduepspyoMjPGuwerQuMj5ZsX_heVuebHv1vnzpo6r7-XaCewOo5QlSl5xFLjfQnJmLbu6egeuzp_EaONDcvIlRU6oB0bD6U2O3l-bxiH_2nZyEnT3fU-neqXm9d3_YiuvAigt_yC_ueEUefiL9A1RJVJHq_7fbu16JE7Jvojm0Uu285dnT2WynYp3luQLCB78oK-sD0LK-lcE5mhHiHTw_hjkL4deTROX37lv3b6NIv976ysyGQ4LnfS5WOARf4JtRkfS0nMNGQ92jRo7z88R6dwSpTkZZQlrXjlGEOU4sOxlBGCZRHeyxpTR2Cheo3uPCzMrRrl_N5sL5IXxws74qd2UtQJneyHEI6JWpr8-VlrSGsDpW2uix_YoGBeTlS-p3JjT6FquwQlNITqY0V5msUt_PK_xs6ros8BoIbFSJ4bwAtRB2lfPFJTcCg8AUXlTDdrv8VXsznlfy8QdhYsKz_x0GWZ-FODvrxnM5Lo_DkaBsqhEpUnuz6-0xdStseXbQ3ckF0c0CHHhVy4Hlgp2YcsDzMT66bwaEz8-Rtc-pjWxQJqhigYpNTjBFz16ZlHjJF_wl0Jr_e6va2Dy3RDXI2mK67wH6ZXNq4hOFG9YYMN1mXyfgikSjwbEXpoA2_r2UI7sjKXa9lo42nartMyXbFr2ffX038eLsw.EfN6sOtoM2Gb0w7BA5lgxA',
    };
  }

  // Helper para construir URLs de forma segura
  Uri _buildUrl(String endpoint) {
    String cleanBase = _baseUrl.endsWith('/') 
        ? _baseUrl.substring(0, _baseUrl.length - 1) 
        : _baseUrl;
        
    String cleanEndpoint = endpoint.startsWith('/') 
        ? endpoint.substring(1) 
        : endpoint;
        
    return Uri.parse('$cleanBase/$cleanEndpoint');
  }

  // GET Request
  Future<dynamic> get(String endpoint) async {
    final url = _buildUrl(endpoint);
    
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
    final url = _buildUrl(endpoint);
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

  // POST Multipart Request (FormData)
  Future<dynamic> postMultipart(
    String endpoint, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    final url = _buildUrl(endpoint);
    
    // Create multipart request
    var request = http.MultipartRequest('POST', url);
    
    // Add default headers (excluding Content-Type as it's set by MultipartRequest)
    final headers = _headers;
    headers.remove('Content-Type');
    request.headers.addAll(headers);

    // Add fields
    if (fields != null) {
      request.fields.addAll(fields);
    }

    // Add files
    if (files != null) {
      request.files.addAll(files);
    }

    _logRequest('POST (MULTIPART)', url, request.headers, body: 'Fields: $fields, Files: ${files?.map((f) => f.field).toList()}');

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      _logResponse(response);
      return _processResponse(response);
    } catch (e) {
      _logError('POST (MULTIPART)', url, e);
      rethrow;
    }
  }

  // PUT Request
  Future<dynamic> put(String endpoint, {dynamic body}) async {
    final url = _buildUrl(endpoint);
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
    final url = _buildUrl(endpoint);

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
    print('------------------------------------------------------------------');
    print('🚀 REQUEST [$method]');
    print('URL: $url');
    print('Headers: $headers');
    if (body != null) {
      print('Body: $body');
    }
    print('------------------------------------------------------------------');
  }

  void _logResponse(http.Response response) {
    print('------------------------------------------------------------------');
    print('📥 RESPONSE [${response.statusCode}]');
    print('URL: ${response.request?.url}');
    print('Body: ${response.body}');
    print('------------------------------------------------------------------');
  }

  void _logError(String method, Uri url, Object error) {
    print('------------------------------------------------------------------');
    print('❌ ERROR [$method]');
    print('URL: $url');
    print('Details: $error');
    print('------------------------------------------------------------------');
  }
}