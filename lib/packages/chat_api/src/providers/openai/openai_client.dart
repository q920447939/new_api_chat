import 'dart:async';
import 'dart:convert';

import '../../chat_api_client.dart';
import '../../errors/chat_api_exception.dart';
import '../../http/chat_http_client.dart';
import '../../models/chat_completion.dart';
import '../../models/chat_message.dart';
import '../../models/chat_stream_event.dart';
import 'openai_models.dart';
import 'openai_provider.dart';

class OpenAIChatClient implements ChatApiClient {
  OpenAIChatClient({required ChatHttpClient httpClient})
      : _httpClient = httpClient;

  final ChatHttpClient _httpClient;

  static const String _completionsPath = '/chat/completions';

  @override
  String get providerId => OpenAIChatProvider.providerId;

  @override
  Future<ChatCompletionResult> createChatCompletion(
    ChatCompletionRequest request, {
    ChatRequestOptions? options,
  }) async {
    final openAiRequest = _ensureOpenAIRequest(request);
    final payload = openAiRequest.copyWith(stream: false).toJson();

    final response = await _httpClient.postJson<Map<String, dynamic>>(
      _completionsPath,
      data: payload,
      options: options,
    );

    final data = _castResponseData(response.data);
    final completion = OpenAIChatCompletionResponse.fromJson(data);
    return completion.toChatCompletionResult();
  }

  @override
  Stream<ChatStreamEvent> createChatCompletionStream(
    ChatCompletionRequest request, {
    ChatRequestOptions? options,
  }) async* {
    final openAiRequest = _ensureOpenAIRequest(request).copyWith(stream: true);
    final aggregator = _OpenAIStreamAggregator();
    final buffer = StringBuffer();

    try {
      final stream = _httpClient.postSseStream(
        _completionsPath,
        data: openAiRequest.toJson(),
        options: options,
      );

      await for (final rawChunk in stream) {
        buffer.write(rawChunk);
        final segments = buffer.toString().split('\n\n');

        for (var i = 0; i < segments.length - 1; i++) {
          final payload = _extractSsePayload(segments[i]);
          if (payload == null) {
            continue;
          }

          if (payload == '[DONE]') {
            final result = aggregator.buildResult();
            yield ChatStreamEvent.done(result);
            return;
          }

          final chunk = parseOpenAIStreamEvent(payload);
          if (chunk == null) {
            continue;
          }

          for (final event in aggregator.handleChunk(chunk)) {
            yield event;
          }
        }

        buffer
          ..clear()
          ..write(segments.last);
      }

      final trailingPayload = _extractSsePayload(buffer.toString());
      if (trailingPayload != null) {
        if (trailingPayload == '[DONE]') {
          final result = aggregator.buildResult();
          yield ChatStreamEvent.done(result);
          return;
        }

        final chunk = parseOpenAIStreamEvent(trailingPayload);
        if (chunk != null) {
          for (final event in aggregator.handleChunk(chunk)) {
            yield event;
          }
        }
      }

      // Stream ended without explicit [DONE] - emit aggregated result.
      yield ChatStreamEvent.done(aggregator.buildResult());
    } catch (error, stack) {
      yield ChatStreamEvent.error(error);
      throw ChatApiException(
        'OpenAI streaming request failed',
        details: {'error': error.toString(), 'stack': stack.toString()},
      );
    }
  }

  OpenAIChatCompletionRequest _ensureOpenAIRequest(ChatCompletionRequest request) {
    if (request is OpenAIChatCompletionRequest) {
      return request;
    }
    throw ArgumentError.value(
      request.runtimeType,
      'request',
      'OpenAI provider expects an OpenAIChatCompletionRequest instance.',
    );
  }

  Map<String, dynamic> _castResponseData(Map<String, dynamic>? data) {
    if (data != null) {
      return data;
    }
    throw ChatApiException('OpenAI response body was empty.');
  }
}

String? _extractSsePayload(String segment) {
  if (segment.isEmpty) {
    return null;
  }
  final lines = const LineSplitter().convert(segment);
  final dataLines = <String>[];
  for (final line in lines) {
    if (line.startsWith('data:')) {
      dataLines.add(line.substring(5).trimRight());
    }
  }
  if (dataLines.isEmpty) {
    return null;
  }
  return dataLines.join('\n');
}

class _OpenAIStreamAggregator {
  final Map<int, _ChoiceAccumulator> _choices = {};
  ChatUsage? _usage;

  Iterable<ChatStreamEvent> handleChunk(OpenAIChatCompletionChunk chunk) sync* {
    if (chunk.usage != null) {
      _usage = chunk.usage!.toUsage();
    }

    for (final choice in chunk.choices) {
      final accumulator = _choices.putIfAbsent(
        choice.index,
        () => _ChoiceAccumulator(choice.index),
      );
      final delta = accumulator.applyDelta(choice);
      if (delta != null) {
        yield ChatStreamEvent.delta(delta);
      }
    }
  }

  ChatCompletionResult buildResult() {
    final sortedChoices = _choices.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final messages = sortedChoices
        .map((entry) => entry.value.buildMessage())
        .toList();

    final finishReason = sortedChoices
        .map((entry) => entry.value.finishReason)
        .firstWhere(
          (reason) => reason != null && reason.isNotEmpty,
          orElse: () => null,
        );

    return ChatCompletionResult(
      messages: messages,
      finishReason: finishReason,
      usage: _usage,
    );
  }
}

class _ChoiceAccumulator {
  _ChoiceAccumulator(this.index);

  final int index;
  ChatMessageRole role = ChatMessageRole.assistant;
  final StringBuffer _contentBuffer = StringBuffer();
  final Map<int, _ToolCallAccumulator> _toolCalls = {};
  String? finishReason;

  ChatDelta? applyDelta(OpenAIChatCompletionDeltaChoice choice) {
    ChatMessageRole? roleDelta;
    String? contentDelta;
    List<ChatToolCallDelta>? toolCallDeltas;

    if (choice.delta.role != null) {
      roleDelta = OpenAIMessageMapper.roleFromString(choice.delta.role);
      role = roleDelta;
    }

    if (choice.delta.content != null && choice.delta.content!.isNotEmpty) {
      _contentBuffer.write(choice.delta.content);
      contentDelta = choice.delta.content;
    }

    if (choice.delta.toolCalls != null && choice.delta.toolCalls!.isNotEmpty) {
      toolCallDeltas = [];
      for (final toolDelta in choice.delta.toolCalls!) {
        final accumulator = _toolCalls.putIfAbsent(
          toolDelta.index,
          () => _ToolCallAccumulator(toolDelta.index),
        );
        final emitted = accumulator.apply(toolDelta);
        if (emitted != null) {
          toolCallDeltas.add(emitted);
        }
      }
      if (toolCallDeltas.isEmpty) {
        toolCallDeltas = null;
      }
    }

    if (choice.finishReason != null) {
      finishReason = choice.finishReason;
    }

    if (roleDelta == null &&
        contentDelta == null &&
        toolCallDeltas == null &&
        choice.finishReason == null) {
      return null;
    }

    return ChatDelta(
      role: roleDelta ?? role,
      content: contentDelta,
      toolCalls: toolCallDeltas,
      finishReason: choice.finishReason,
      metadata: {'choice_index': index},
    );
  }

  ChatMessage buildMessage() {
    final text = _contentBuffer.toString();
    final parts = <ChatContentPart>[];
    if (text.isNotEmpty) {
      parts.add(ChatTextContent(text));
    }
    final metadata = _toolCalls.isEmpty
        ? null
        : {
            'tool_calls': _toolCalls.entries.map((entry) => entry.value.toJson()).toList(),
          };
    if (parts.isEmpty) {
      parts.add(const ChatTextContent(''));
    }
    return ChatMessage(
      role: role,
      contentParts: parts,
      metadata: metadata,
    );
  }
}

class _ToolCallAccumulator {
  _ToolCallAccumulator(this.index);

  final int index;
  String? id;
  String? type;
  String? name;
  final StringBuffer _arguments = StringBuffer();

  ChatToolCallDelta? apply(OpenAIToolCallDelta delta) {
    if (delta.id != null) {
      id = delta.id;
    }
    if (delta.type != null) {
      type = delta.type;
    }
    if (delta.function?.name != null && delta.function!.name!.isNotEmpty) {
      name = delta.function!.name;
    }
    String? argumentsDelta;
    if (delta.function?.arguments != null &&
        delta.function!.arguments!.isNotEmpty) {
      _arguments.write(delta.function!.arguments);
      argumentsDelta = delta.function!.arguments;
    }

    if (delta.id == null &&
        argumentsDelta == null &&
        delta.function?.name == null &&
        delta.type == null) {
      return null;
    }

    return ChatToolCallDelta(
      id: id ?? '',
      type: type ?? 'function',
      name: name,
      argumentsDelta: argumentsDelta,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      if (id != null) 'id': id,
      'type': type ?? 'function',
      'function': {
        if (name != null) 'name': name,
        'arguments': _arguments.toString(),
      },
    };
  }
}
