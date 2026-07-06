import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _baseUrl = 'http://127.0.0.1:8000/api/v1';

class BarberApi {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ))..interceptors.addAll([_AuthInterceptor(), _NumCoercionInterceptor()]);

  static Dio get instance => _dio;
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

String? _accessToken;
String? _refreshToken;

Future<void> loadTokens() async {
  final prefs = await SharedPreferences.getInstance();
  _accessToken = prefs.getString('barber_access');
  _refreshToken = prefs.getString('barber_refresh');
}

Future<void> setTokens(String access, String refresh) async {
  _accessToken = access;
  _refreshToken = refresh;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('barber_access', access);
  await prefs.setString('barber_refresh', refresh);
}

Future<void> clearTokens() async {
  _accessToken = null;
  _refreshToken = null;
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('barber_access');
  await prefs.remove('barber_refresh');
}

bool get isLoggedIn => _accessToken != null;

class _AuthInterceptor extends Interceptor {
  bool _isRefreshing = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_accessToken != null) {
      options.headers['Authorization'] = 'Bearer $_accessToken';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing && _refreshToken != null) {
      _isRefreshing = true;
      try {
        final res = await Dio().post('$_baseUrl/auth/token/refresh/', data: {'refresh': _refreshToken});
        final newAccess = res.data['access'] as String;
        await setTokens(newAccess, _refreshToken!);
        final opts = err.requestOptions..headers['Authorization'] = 'Bearer $newAccess';
        final retry = await BarberApi.instance.fetch(opts);
        _isRefreshing = false;
        return handler.resolve(retry);
      } catch (_) {
        await clearTokens();
      }
      _isRefreshing = false;
    }
    handler.next(err);
  }
}
