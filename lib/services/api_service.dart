import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: AppConstants.apiTimeoutSeconds),
      receiveTimeout: const Duration(seconds: AppConstants.apiTimeoutSeconds),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        appLogger.d('API Request: ${options.method} ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        appLogger.d('API Response: ${response.statusCode}');
        handler.next(response);
      },
      onError: (error, handler) {
        appLogger.e('API Error: ${error.message}', error: error);
        handler.next(error);
      },
    ));

    _dio.interceptors.add(_RetryInterceptor(_dio));
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) => _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) => _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);
}

class _RetryInterceptor extends Interceptor {
  final Dio dio;
  int _retryCount = 0;

  _RetryInterceptor(this.dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_retryCount < AppConstants.maxRetries &&
        err.type == DioExceptionType.connectionTimeout) {
      _retryCount++;
      final delay = Duration(seconds: 1 << (_retryCount - 1)); // 指数バックオフ
      await Future.delayed(delay);
      try {
        final response = await dio.fetch(err.requestOptions);
        _retryCount = 0;
        handler.resolve(response);
        return;
      } catch (e) {
        // retry失敗時は次のinterceptorへ
      }
    }
    _retryCount = 0;
    handler.next(err);
  }
}
