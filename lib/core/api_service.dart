// lib/core/api_service.dart
// Singleton Dio-based HTTP client with interceptors
// Handles authentication, device headers, and error mapping

import 'package:dio/dio.dart';
import 'constants.dart';
import 'auth_service.dart';

/// Custom API exceptions
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class NetworkException extends ApiException {
  NetworkException(super.message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([String? message]) : super(message ?? 'Non autorisé', statusCode: 401);
}

class ValidationException extends ApiException {
  ValidationException(String message, {dynamic data})
      : super(message, statusCode: 422, data: data);
}

class ServerException extends ApiException {
  ServerException(String message, {int? statusCode})
      : super(message, statusCode: statusCode);
}

/// Authentication interceptor - adds Bearer token to requests
class AuthInterceptor extends Interceptor {
  String? _token;

  void setToken(String? token) {
    _token = token;
    print('[AuthInterceptor] Token ${token != null ? 'set' : 'cleared'}');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_token != null && _token!.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $_token';
    }
    super.onRequest(options, handler);
  }
}

/// Device interceptor - adds device information headers
class DeviceInterceptor extends Interceptor {
  final Map<String, String> _deviceHeaders = {};

  void setDeviceHeaders(Map<String, String> headers) {
    _deviceHeaders.clear();
    _deviceHeaders.addAll(headers);
    print('═══════════════════════════════════════════════════════');
    print('[DeviceInterceptor] 🔧 Device headers configured:');
    headers.forEach((key, value) {
      print('  $key: $value');
    });
    print('═══════════════════════════════════════════════════════');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.addAll(_deviceHeaders);
    super.onRequest(options, handler);
  }
}


/// Error interceptor - maps DioException to custom exceptions
class ErrorInterceptor extends Interceptor {
  static Function()? _onUnauthorized;

  /// Définir le callback pour gérer la déconnexion
  static void setOnUnauthorizedCallback(Function() callback) {
    _onUnauthorized = callback;
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('[ErrorInterceptor] Error: ${err.type} - ${err.message}');

    ApiException exception;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        exception = NetworkException('Connection timeout');
        break;

      case DioExceptionType.connectionError:
        exception = NetworkException('No internet connection');
        break;

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final message = err.response?.data?['message'] ?? 'Unknown error';

        switch (statusCode) {
          case 401:
            // Déconnecter automatiquement l'utilisateur en cas d'erreur 401
            _handleUnauthorized();
            exception = UnauthorizedException(message);
            break;
          case 422:
            exception = ValidationException(
              message,
              data: err.response?.data,
            );
            break;
          case 500:
          case 502:
          case 503:
            exception = ServerException(
              'Server error: $message',
              statusCode: statusCode,
            );
            break;
          default:
            exception = ApiException(
              message,
              statusCode: statusCode,
              data: err.response?.data,
            );
        }
        break;

      case DioExceptionType.cancel:
        exception = ApiException('Request cancelled');
        break;

      default:
        exception = ApiException('Unknown error: ${err.message}');
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        type: err.type,
        response: err.response,
      ),
    );
  }

  /// Gérer la déconnexion automatique en cas d'erreur 401
  void _handleUnauthorized() {
    print('[ErrorInterceptor] Handling 401 Unauthorized - logging out user');
    
    // Appeler le callback de déconnexion s'il est défini
    if (_onUnauthorized != null) {
      try {
        _onUnauthorized!();
        print('[ErrorInterceptor] User logged out due to 401 error');
      } catch (e) {
        print('[ErrorInterceptor] Error during logout: $e');
      }
    } else {
      // Ne pas appeler AuthService directement pour éviter les conflits avec les providers
      print('[ErrorInterceptor] No logout callback set - user should be logged out manually');
    }
  }
}

/// API Service for HTTP communication
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  late final AuthInterceptor _authInterceptor;
  late final DeviceInterceptor _deviceInterceptor;

  bool _isInitialized = false;

  /// Initialize API service with base configuration
  void init() {
    if (_isInitialized) {
      print('[ApiService] Already initialized');
      return;
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
      ),
    );

    // Add interceptors
    _authInterceptor = AuthInterceptor();
    _deviceInterceptor = DeviceInterceptor();

    _dio.interceptors.addAll([
      _authInterceptor,
      _deviceInterceptor,
      ErrorInterceptor(),
    ]);

    _isInitialized = true;
    print('[ApiService] Initialized with base URL: ${AppConstants.baseUrl}');
  }

  /// Set authentication token
  void setToken(String token) {
    _authInterceptor.setToken(token);
  }

  /// Clear authentication token
  void clearToken() {
    _authInterceptor.setToken(null);
  }

  /// Set device headers
  void setDeviceHeaders(Map<String, String> headers) {
    _deviceInterceptor.setDeviceHeaders(headers);
  }

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      _logRequest('GET', path, queryParameters: queryParameters);

      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );

      _logResponse('GET', path, response);
      return response;
    } on DioException catch (e) {
      _logError('GET', path, e);
      throw e.error ?? ApiException('Request failed');
    }
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      _logRequest('POST', path, data: data, queryParameters: queryParameters);

      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      _logResponse('POST', path, response);
      return response;
    } on DioException catch (e) {
      _logError('POST', path, e);
      throw e.error ?? ApiException('Request failed');
    }
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      _logRequest('PUT', path, data: data, queryParameters: queryParameters);

      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      _logResponse('PUT', path, response);
      return response;
    } on DioException catch (e) {
      _logError('PUT', path, e);
      throw e.error ?? ApiException('Request failed');
    }
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      _logRequest('DELETE', path, data: data, queryParameters: queryParameters);

      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      _logResponse('DELETE', path, response);
      return response;
    } on DioException catch (e) {
      _logError('DELETE', path, e);
      throw e.error ?? ApiException('Request failed');
    }
  }

  /// PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      _logRequest('PATCH', path, data: data, queryParameters: queryParameters);

      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      _logResponse('PATCH', path, response);
      return response;
    } on DioException catch (e) {
      _logError('PATCH', path, e);
      throw e.error ?? ApiException('Request failed');
    }
  }

  /// Log request details
  void _logRequest(String method, String path, {dynamic data, Map<String, dynamic>? queryParameters}) {
    print('');
    print('╔═══════════════════════════════════════════════════════╗');
    print('║ 📤 API REQUEST                                        ║');
    print('╠═══════════════════════════════════════════════════════╣');
    print('║ Method: $method');
    print('║ Path:   $path');
    print('║ URL:    ${AppConstants.baseUrl}$path');

    // Afficher les headers qui seront envoyés
    print('║ Headers:');
    print('║   Content-Type: application/json');
    print('║   Accept: application/json');
    if (_authInterceptor._token != null) {
      final tokenPreview = _authInterceptor._token!.length > 30
          ? '${_authInterceptor._token!.substring(0, 30)}...'
          : _authInterceptor._token!;
      print('║   Authorization: Bearer $tokenPreview');
    }

    // Afficher les device headers
    final deviceHeaders = _deviceInterceptor._deviceHeaders;
    if (deviceHeaders.isNotEmpty) {
      deviceHeaders.forEach((key, value) {
        final valueDisplay = value.length > 50 ? '${value.substring(0, 47)}...' : value;
        print('║   $key: $valueDisplay');
      });
    }

    if (queryParameters != null && queryParameters.isNotEmpty) {
      print('║ Query Parameters:');
      queryParameters.forEach((key, value) {
        print('║   $key: $value');
      });
    }

    if (data != null) {
      print('║ Body:');
      final bodyStr = data.toString();
      if (bodyStr.length > 500) {
        print('║   ${bodyStr.substring(0, 497)}...');
      } else {
        print('║   $bodyStr');
      }
    }

    print('╚═══════════════════════════════════════════════════════╝');
    print('');
  }

  /// Log response details
  void _logResponse(String method, String path, Response response) {
    print('');
    print('╔═══════════════════════════════════════════════════════╗');
    print('║ 📥 API RESPONSE                                       ║');
    print('╠═══════════════════════════════════════════════════════╣');
    print('║ Method: $method');
    print('║ Path:   $path');
    print('║ Status: ${response.statusCode} ${response.statusMessage ?? ''}');

    if (response.headers.map.isNotEmpty) {
      print('║ Headers:');
      response.headers.map.forEach((key, values) {
        if (key.toLowerCase() != 'authorization') { // Ne pas logger le token
          print('║   $key: ${values.join(', ')}');
        }
      });
    }

    if (response.data != null) {
      print('║ Response Body:');
      final responseStr = response.data.toString();
      if (responseStr.length > 500) {
        print('║   ${responseStr.substring(0, 497)}...');
      } else {
        print('║   $responseStr');
      }
    }

    print('╚═══════════════════════════════════════════════════════╝');
    print('');
  }

  /// Log error details
  void _logError(String method, String path, DioException error) {
    print('');
    print('╔═══════════════════════════════════════════════════════╗');
    print('║ ❌ API ERROR                                          ║');
    print('╠═══════════════════════════════════════════════════════╣');
    print('║ Method: $method');
    print('║ Path:   $path');
    print('║ Type:   ${error.type}');
    print('║ Message: ${error.message}');

    if (error.response != null) {
      print('║ Status: ${error.response!.statusCode}');
      if (error.response!.data != null) {
        print('║ Error Data:');
        final errorStr = error.response!.data.toString();
        if (errorStr.length > 500) {
          print('║   ${errorStr.substring(0, 497)}...');
        } else {
          print('║   $errorStr');
        }
      }
    }

    print('╚═══════════════════════════════════════════════════════╝');
    print('');
  }

  /// Get Dio instance for advanced usage
  Dio get dio => _dio;
}
