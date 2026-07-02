import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../error/exceptions.dart';

/// Reusable HTTP client. Data sources depend on this — never repositories directly.
class ApiClient {
  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: ApiConstants.connectTimeout,
                receiveTimeout: ApiConstants.receiveTimeout,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  final Dio _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<T>(path, queryParameters: queryParameters);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
  }) async {
    try {
      return await _dio.post<T>(path, data: data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
  }) async {
    try {
      return await _dio.put<T>(path, data: data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<Response<T>> delete<T>(String path) async {
    try {
      return await _dio.delete<T>(path);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  AppException _mapDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        if (statusCode >= 500) {
          return ServerException('Server error ($statusCode)');
        }
        return ServerException(
          error.response?.statusMessage ?? 'Request failed ($statusCode)',
        );
      default:
        return UnexpectedException(error.message ?? 'Unexpected network error');
    }
  }
}
