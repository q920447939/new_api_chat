import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:new_api_chat/packages/chat_api/chat_api.dart';

/// Integration playground that exercises the OpenAI-compatible chat provider
/// against a configurable endpoint.
class ChatApiTestPage extends StatefulWidget {
  const ChatApiTestPage({super.key});

  @override
  State<ChatApiTestPage> createState() => _ChatApiTestPageState();
}

class _ChatApiTestPageState extends State<ChatApiTestPage> {
  final TextEditingController _baseUrlController = TextEditingController(
    text: 'http://106.75.153.196:13000/v1',
  );
  final TextEditingController _apiKeyController = TextEditingController(
    text: 'sk-12GATArJ7z35tEZ0JRfI9bp5m1CPIBE0ivg9v5sC2F2hJWvU',
  );
  final TextEditingController _modelController = TextEditingController(
    text: 'deepseek-ai/DeepSeek-V3.1',
  );
  final TextEditingController _systemController = TextEditingController(
    text: '你是一个有帮助的助手。',
  );
  final TextEditingController _userInputController = TextEditingController();

  final List<_ConversationEntry> _entries = [];
  final List<ChatMessage> _history = [];

  bool _useStream = false;
  bool _isSending = false;

  CancelToken? _currentCancelToken;

  @override
  void initState() {
    super.initState();
    // Ensure the real OpenAI-compatible provider is registered.
    OpenAIChatProvider.register(overrideExisting: true);
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _systemController.dispose();
    _userInputController.dispose();
    _cancelOngoingRequest();
    super.dispose();
  }

  void _cancelOngoingRequest() {
    if (_currentCancelToken != null && !_currentCancelToken!.isCancelled) {
      _currentCancelToken!.cancel('用户取消');
    }
    _currentCancelToken = null;
  }

  Future<void> _handleSend() async {
    final text = _userInputController.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }
    final baseUrl = _baseUrlController.text.trim();
    final apiKey = _apiKeyController.text.trim();
    final model = _modelController.text.trim();

    if (baseUrl.isEmpty || apiKey.isEmpty || model.isEmpty) {
      _showSnackBar('请先填写 Base URL、API Key 和 Model。');
      return;
    }

    setState(() {
      _isSending = true;
      _userInputController.clear();
      final entry = _ConversationEntry(
        role: ChatMessageRole.user,
        content: text,
      );
      _entries.add(entry);
      _history.add(ChatMessage.text(role: ChatMessageRole.user, text: text));
    });

    final request = _buildRequest(model: model);
    final manager = _buildManager(baseUrl: baseUrl, apiKey: apiKey);

    setState(() {
      _useStream = true;
    });
    if (_useStream) {
      await _runStreamCompletion(manager, request);
    } else {
      await _runSingleCompletion(manager, request);
    }

    if (mounted) {
      setState(() {
        _isSending = false;
      });
    }
  }

  ChatApiManager _buildManager({
    required String baseUrl,
    required String apiKey,
  }) {
    final normalizedUrl = _normalizeBaseUrl(baseUrl);
    return ChatApiManager(
      OpenAIConfig(
        apiKey: apiKey,
        baseUrl: normalizedUrl,
        requestTimeout: const Duration(seconds: 60),
      ),
    );
  }

  OpenAIChatCompletionRequest _buildRequest({required String model}) {
    final systemText = _systemController.text.trim();
    final messages = <ChatMessage>[
      if (systemText.isNotEmpty)
        ChatMessage.text(role: ChatMessageRole.system, text: systemText),
      ..._history,
    ];

    return OpenAIChatCompletionRequest(
      model: model,
      messages: messages,
      temperature: 0.7,
      stream: _useStream,
      metadata: const {'origin': 'chat_api_test'},
    );
  }

  Future<void> _runSingleCompletion(
    ChatApiManager manager,
    OpenAIChatCompletionRequest request,
  ) async {
    final replyEntry = _ConversationEntry(
      role: ChatMessageRole.assistant,
      content: '',
      isStreaming: false,
    );
    try {
      _currentCancelToken = CancelToken();
      final result = await manager.createChatCompletion(
        request,
        options: ChatRequestOptions(cancelToken: _currentCancelToken),
      );
      final replyText = _extractAssistantText(result.messages);
      replyEntry
        ..content = replyText
        ..usage = result.usage;
      setState(() {
        _entries.add(replyEntry);
        _history.addAll(result.messages);
      });
    } catch (error) {
      replyEntry.content = '调用失败：$error';
      setState(() {
        _entries.add(replyEntry);
      });
    } finally {
      _currentCancelToken = null;
    }
  }

  Future<void> _runStreamCompletion(
    ChatApiManager manager,
    OpenAIChatCompletionRequest request,
  ) async {
    final replyEntry = _ConversationEntry(
      role: ChatMessageRole.assistant,
      content: '',
      isStreaming: true,
    );
    setState(() {
      _entries.add(replyEntry);
    });

    _currentCancelToken = CancelToken();

    try {
      final stream = manager.createChatCompletionStream(
        request,
        options: ChatRequestOptions(cancelToken: _currentCancelToken),
      );
      await for (final event in stream) {
        if (!mounted) {
          break;
        }
        if (event.isDelta) {
          final chunk = event.delta?.content;
          if (chunk != null && chunk.isNotEmpty) {
            setState(() {
              replyEntry.content += chunk;
            });
          }
        } else if (event.isDone && event.result != null) {
          final finalResult = event.result!;
          setState(() {
            replyEntry
              ..content = _extractAssistantText(finalResult.messages)
              ..isStreaming = false
              ..usage = finalResult.usage;
            _history.addAll(finalResult.messages);
          });
        } else if (event.isError) {
          setState(() {
            replyEntry
              ..content = '流式错误：${event.error}'
              ..isStreaming = false;
          });
        }
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        replyEntry
          ..content = '流式调用失败：$error'
          ..isStreaming = false;
      });
    } finally {
      _currentCancelToken = null;
    }
  }

  void _handleClear() {
    _cancelOngoingRequest();
    setState(() {
      _entries.clear();
      _history.clear();
    });
  }

  String _extractAssistantText(List<ChatMessage> messages) {
    final buffer = StringBuffer();
    for (final message in messages) {
      if (message.role != ChatMessageRole.assistant) {
        continue;
      }
      for (final part in message.contentParts) {
        if (part is ChatTextContent) {
          buffer.write(part.text);
        }
      }
    }
    return buffer.toString();
  }

  String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('聊天接口测试'),
        actions: [
          Switch(
            value: _useStream,
            onChanged: _isSending
                ? null
                : (value) {
                    setState(() {
                      _useStream = value;
                    });
                  },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: Text('Stream')),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildConfigPanel(),
          const Divider(height: 1),
          Expanded(child: _buildConversationList()),
          const Divider(height: 1),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildConfigPanel() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ConfigField(
            controller: _baseUrlController,
            label: 'Base URL',
            hintText: '例如：http://106.75.153.196:13000/v1',
            enabled: !_isSending,
          ),
          const SizedBox(height: 12),
          _ConfigField(
            controller: _apiKeyController,
            label: 'Authorization',
            hintText: 'Bearer Token',
            enabled: !_isSending,
            obscureText: true,
          ),
          const SizedBox(height: 12),
          _ConfigField(
            controller: _modelController,
            label: 'Model',
            hintText: '例如：deepseek-ai/DeepSeek-V3.1',
            enabled: !_isSending,
          ),
          const SizedBox(height: 12),
          _ConfigField(
            controller: _systemController,
            label: '系统提示词（System Prompt）',
            hintText: '你是一个有帮助的助手。',
            enabled: !_isSending,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _isSending ? null : _handleClear,
                icon: const Icon(Icons.refresh),
                label: const Text('清空对话'),
              ),
              const SizedBox(width: 12),
              if (_isSending)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList() {
    if (_entries.isEmpty) {
      return const Center(
        child: Text('填写配置信息后，发送一条消息测试接口响应。'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        final isUser = entry.role == ChatMessageRole.user;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isUser ? Colors.blue.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    SelectableText(entry.content),
                    if (entry.usage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Tokens: in ${entry.usage!.inputTokens} / out ${entry.usage!.outputTokens}',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                    if (entry.isStreaming)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Streaming...',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _userInputController,
              enabled: !_isSending,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '输入对话内容...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _isSending ? null : _handleSend,
            icon: const Icon(Icons.send),
            label: const Text('发送'),
          ),
        ],
      ),
    );
  }
}

class _ConversationEntry {
  _ConversationEntry({
    required this.role,
    required this.content,
    this.isStreaming = false,
    this.usage,
  });

  final ChatMessageRole role;
  String content;
  bool isStreaming;
  ChatUsage? usage;
}

class _ConfigField extends StatelessWidget {
  const _ConfigField({
    required this.controller,
    required this.label,
    this.hintText,
    this.enabled = true,
    this.obscureText = false,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool enabled;
  final bool obscureText;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
