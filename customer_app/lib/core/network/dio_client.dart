import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class DioClient {
  static Dio? _instance;
  static final _storage = FlutterSecureStorage();

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));

    dio.interceptors.addAll([
      _AuthInterceptor(dio),
      _NumCoercionInterceptor(),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);

    return dio;
  }
}

class _NumCoercionInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    response.data = _coerce(response.data);
    handler.next(response);
  }

  dynamic _coerce(dynamic v) {
    if (v is Map) {
      return Map<String, dynamic>.fromEntries(
        v.entries.map((e) => MapEntry(e.key.toString(), _coerce(e.value))),
      );
    }
    if (v is List) return v.map(_coerce).toList();
    if (v is String) {
      final n = num.tryParse(v);
      if (n != null) return n;
    }
    return v;
  }
}

class _AuthInterceptor extends Interceptor {
  final Dio dio;
  static const _storage = FlutterSecureStorage();
  bool _isRefreshing = false;

  _AuthInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refresh = await _storage.read(key: AppConstants.refreshTokenKey);
        if (refresh == null) {
          handler.reject(err);
          return;
        }
        final res = await dio.post(
          '/auth/token/refresh/',
          data: {'refresh': refresh},
          options: Options(headers: {'Authorization': null}),
        );
        final newAccess = res.data['access'];
        await _storage.write(key: AppConstants.accessTokenKey, value: newAccess);
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
        final retried = await dio.fetch(err.requestOptions);
        handler.resolve(retried);
      } catch (_) {
        await _storage.deleteAll();
        handler.reject(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }
}
