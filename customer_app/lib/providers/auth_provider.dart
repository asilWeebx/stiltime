import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../core/constants/app_constants.dart';
import '../core/network/dio_client.dart';
import '../data/models/user_model.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) => AuthState(
    user: user ?? this.user,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  static const _storage = FlutterSecureStorage();

  AuthNotifier() : super(const AuthState()) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userJson = await _storage.read(key: AppConstants.userKey);
    if (userJson != null) {
      state = state.copyWith(user: UserModel.fromJson(jsonDecode(userJson)));
    }
  }

  Future<void> sendOTP(String phone) async {
    await DioClient.instance.post('/auth/send-otp/', data: {'phone': phone});
  }

  // Returns true if this is a new user (needs profile completion)
  Future<bool> verifyOTP(String phone, String code) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await DioClient.instance.post('/auth/verify-otp/', data: {'phone': phone, 'code': code});
      final data = res.data;
      final user = UserModel.fromJson(data['user']);
      await _storage.write(key: AppConstants.accessTokenKey, value: data['tokens']['access']);
      await _storage.write(key: AppConstants.refreshTokenKey, value: data['tokens']['refresh']);
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
      state = state.copyWith(user: user, isLoading: false);
      // New user if fullName is empty or API explicitly flags it
      final isNew = data['is_new_user'] == true || user.fullName.trim().isEmpty;
      return isNew;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateProfile(dynamic data) async {
    final res = await DioClient.instance.patch('/users/me/', data: data);
    final user = UserModel.fromJson(res.data);
    await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
    state = state.copyWith(user: user);
  }

  Future<void> logout() async {
    try {
      final refresh = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refresh != null) {
        await DioClient.instance.post('/auth/logout/', data: {'refresh': refresh});
      }
    } catch (_) {}
    await _storage.deleteAll();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
