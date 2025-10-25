import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/chat_api_config.dart';
import '../errors/chat_api_exception.dart';
import '../models/chat_completion.dart';
import 'package:http/http.dart' as http;


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



/// 使用 `http` 包模拟 curl 所示的流式接口调用。
/// 返回值会按 Server-Sent Events (SSE) 的帧逐条产出 `data:` 内容。
Stream<String> createChatCompletionStream({
  required Uri uri,
  required String apiKey,
  required Map<String, Object?> payload,
  http.Client? client,
  Map<String, String>? extraHeaders,
  Duration? timeout,
}) async* {
  final effectiveClient = client ?? http.Client();
  final shouldCloseClient = client == null;

  try {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'Authorization': 'Bearer $apiKey',
      if (extraHeaders != null) ...extraHeaders,
    };

    final request = http.Request('POST', uri)
      ..headers.addAll(headers)
      ..body = jsonEncode(payload);

    final responseFuture = effectiveClient.send(request);
    final response = timeout == null
        ? await responseFuture
        : await responseFuture.timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorBody =
          await response.stream.transform(utf8.decoder).join();
      throw http.ClientException(
        'Streaming request failed with status ${response.statusCode}. '
        'Body: $errorBody',
        uri,
      );
    }

    final frameLines = <String>[];
    final lineStream = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lineStream) {
      if (line.isEmpty) {
        final data = _extractSseData(frameLines);
        frameLines.clear();
        if (data == null) {
          continue;
        }
        yield data;
        if (data.trim() == '[DONE]') {
          return;
        }
        continue;
      }
      frameLines.add(line);
    }

    final trailing = _extractSseData(frameLines);
    if (trailing != null) {
      yield trailing;
    }
  } finally {
    if (shouldCloseClient) {
      effectiveClient.close();
    }
  }
}

String? _extractSseData(List<String> lines) {
  if (lines.isEmpty) {
    return null;
  }

  final dataLines = <String>[];
  for (final line in lines) {
    if (line.startsWith('data:')) {
      dataLines.add(line.substring(5).trimLeft());
    }
  }

  if (dataLines.isEmpty) {
    return null;
  }

  return dataLines.join('\n');
}
