import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// 使用 `http` 包模拟 curl 所示的流式接口调用。
/// 返回值会按 Server-Sent Events (SSE) 的帧逐条产出 `data:` 内容。
Stream<String> createChatCompletionStream({
  required Uri uri,
  required String apiKey,
  required Map<String, Object?> payload,
  http.Client? client,
  Map<String, String>? extraHeaders,
}) async* {
  final effectiveClient = client ?? http.Client();
  final shouldCloseClient = client == null;

  try {
    final request = http.Request('POST', uri)
      ..headers.addAll(<String, String>{
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        'Authorization': 'Bearer $apiKey',
        if (extraHeaders != null) ...extraHeaders,
      })
      ..body = jsonEncode(payload);

    final response = await effectiveClient.send(request);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorBody =
          await response.stream.transform(utf8.decoder).join();
      throw http.ClientException(
        'Streaming request failed with status ${response.statusCode}. '
        'Body: $errorBody',
        uri,
      );
    }

    final lineStream = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    final frameLines = <String>[];

    await for (final line in lineStream) {
      if (line.isEmpty) {
        final data = _extractSseData(frameLines);
        frameLines.clear();
        if (data == null) {
          continue;
        }
        yield data;
        if (data == '[DONE]') {
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

Future<void> main() async {
  final apiKey = "sk-12GATArJ7z35tEZ0JRfI9bp5m1CPIBE0ivg9v5sC2F2hJWvU";
  final client = http.Client();
  final uri = Uri.parse('http://106.75.153.196:13000/v1/chat/completions#');

  final payload = <String, Object?>{
    'model': 'deepseek-ai/DeepSeek-V3.1',
    'messages': [
      {
        'role': 'user',
        'content': 'flutter语言开发规范',
      },
    ],
    'stream': true,
  };

  try {
    await for (final event in createChatCompletionStream(
      uri: uri,
      apiKey: apiKey,
      payload: payload,
      client: client,
    )) {
      if (event == '[DONE]') {
        print('流结束');
        return;
      }

      // SSE 数据通常是 JSON 字符串，这里演示直接打印。
      print('收到片段: $event');
    }
  } finally {
    client.close();
  }
}
