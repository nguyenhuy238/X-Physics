import 'package:dio/dio.dart';
import 'dart:developer' as developer;

import '../constants/api_endpoints.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient(
    String baseUrl, {
    required TokenStorage tokenStorage,
    void Function()? onUnauthorized,
  }) : dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: const Duration(seconds: 8),
           receiveTimeout: const Duration(seconds: 12),
           sendTimeout: const Duration(seconds: 8),
         ),
       ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final isPublicAuthRequest = {
            ApiEndpoints.login,
            ApiEndpoints.register,
            ApiEndpoints.refresh,
            ApiEndpoints.refreshToken,
          }.contains(options.path);
          if (isPublicAuthRequest) {
            handler.next(options);
            return;
          }
          final token = await tokenStorage.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;
          final alreadyRetried = error.requestOptions.extra['retried'] == true;
          final isRefreshRequest =
              error.requestOptions.path == ApiEndpoints.refresh ||
              error.requestOptions.path == ApiEndpoints.refreshToken;
          if (statusCode != 401 || alreadyRetried || isRefreshRequest) {
            if (statusCode == 401 && isRefreshRequest) {
              await tokenStorage.clear();
              onUnauthorized?.call();
            }
            handler.next(error);
            return;
          }

          final refreshToken = await tokenStorage.readRefreshToken();
          if (refreshToken == null || refreshToken.isEmpty) {
            await tokenStorage.clear();
            onUnauthorized?.call();
            handler.next(error);
            return;
          }

          try {
            final response = await dio.post<Map<String, dynamic>>(
              ApiEndpoints.refreshToken,
              data: {'refreshToken': refreshToken},
              options: Options(headers: {'Authorization': null}),
            );
            final data = response.data?['data'] as Map<String, dynamic>?;
            final accessToken = data?['accessToken'] as String?;
            final newRefreshToken = data?['refreshToken'] as String?;
            if (accessToken == null || newRefreshToken == null) {
              throw StateError('Invalid refresh response');
            }
            await tokenStorage.saveTokens(
              accessToken: accessToken,
              refreshToken: newRefreshToken,
            );

            final request = error.requestOptions;
            request.extra['retried'] = true;
            request.headers['Authorization'] = 'Bearer $accessToken';
            final retryResponse = await dio.fetch<dynamic>(request);
            handler.resolve(retryResponse);
          } catch (refreshError, stackTrace) {
            developer.log(
              'Token refresh failed',
              name: 'ApiClient',
              error: refreshError,
              stackTrace: stackTrace,
            );
            await tokenStorage.clear();
            onUnauthorized?.call();
            handler.next(error);
          }
        },
      ),
    );
  }

  final Dio dio;
}
