import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/chat_api_config.dart';
import '../errors/chat_api_exception.dart';
import '../models/chat_completion.dart';

typedef DioFactory = Dio Function(BaseOptions options);

/// Lightweight wrapper around [Dio] that centralises configuration shared
/// across providers.
class ChatHttpClient {
  ChatHttpClient({
    required ChatApiConfig config,
    DioFactory dioFactory = _defaultDioFactory,
  })  : _config = config,
        _dio = dioFactory(
          BaseOptions(
            baseUrl: config.baseUrl ?? '',
            connectTimeout: config.requestTimeout,
            receiveTimeout: config.requestTimeout,
            headers: {
              if (config.apiKey != null) 'Authorization': 'Bearer ${config.apiKey}',
              ...config.defaultHeaders,
            },
          ),
        );

  final ChatApiConfig _config;
  final Dio _dio;

  Dio get dio => _dio;
  ChatApiConfig get config => _config;

  static Dio _defaultDioFactory(BaseOptions options) => Dio(options);

  /// Performs a JSON `POST` request and returns the parsed response.
  Future<Response<T>> postJson<T>(
    String path, {
    required Map<String, dynamic> data,
    ChatRequestOptions? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: options?.queryParameters,
        options: Options(
          headers: options?.headers,
          sendTimeout: options?.timeout,
          receiveTimeout: options?.timeout,
        ),
        cancelToken: options?.cancelToken,
      );
    } on DioException catch (error) {
      throw ChatApiException(
        error.message ?? 'Unknown network error',
        code: error.type.name,
        statusCode: error.response?.statusCode,
        details: {
          'response': error.response?.data,
        },
      );
    }
  }

  /// Performs a streaming `POST` request used by providers that deliver
  /// Server-Sent-Events (SSE) style responses.
  Stream<String> postSseStream(
    String path, {
    required Map<String, dynamic> data,
    ChatRequestOptions? options,
    Map<String, dynamic>? extraHeaders,
  }) async* {
    final mergedHeaders = {
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      if (options?.headers case final headers?) ...headers,
      if (extraHeaders != null) ...extraHeaders,
    };

    Response<ResponseBody> response;
    try {
      response = await _dio.post<ResponseBody>(
        path,
        data: data,
        queryParameters: options?.queryParameters,
        options: Options(
          responseType: ResponseType.stream,
          headers: mergedHeaders,
          sendTimeout: options?.timeout,
          receiveTimeout: options?.timeout,
        ),
        cancelToken: options?.cancelToken,
      );
    } on DioException catch (error) {
      throw ChatApiException(
        error.message ?? 'Failed to establish stream',
        code: error.type.name,
        statusCode: error.response?.statusCode,
        details: {
          'response': error.response?.data,
        },
      );
    }

    final stream = response.data?.stream ??
        const Stream<List<int>>.empty();
    final decoder = utf8.decoder.bind(stream);

    await for (final chunk in decoder) {
      yield chunk;
    }
  }
}
